from snakemake.remote import FTP


FTP = FTP.RemoteProvider()


configfile: "config.yaml"


rule all:
    input:
        expand(["ref/annotation.chr{chrom}.gtf",
                "ref/genome.chr{chrom}.fa"], chrom=config["chrom"]),
        expand("reads/{sample}.chr{chrom}.{group}.fq", 
               group=[1, 2], sample=["a", "b"], chrom=config["chrom"])


rule annotation:
    input:
        FTP.remote("ftp.ensembl.org/pub/release-90/gtf/homo_sapiens/Homo_sapiens.GRCh38.90.gtf.gz", static=True, keep_local=True)
    output:
        "ref/annotation.chr{chrom}.gtf"
    shell:
        "zgrep -P ^{wildcards.chrom} {input} > {output}"


rule genome:
    input:
        FTP.remote("ftp://ftp.ensembl.org/pub/release-90/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.chromosome.{chrom}.fa.gz", static=True, keep_local=True)
    output:
        "ref/genome.chr{chrom}.fa"
    shell:
        "gzip -d -c {input} > {output}"


rule transcripts:
    input:
        ann="ref/annotation.chr{chrom}.gtf",
        seq="ref/genome.chr{chrom}.fa"
    output:
        "ref/transcripts.chr{chrom}.fa"
    conda:
        "envs/mason.yaml"
    shell:
        "mason_splicing --gff-group-by gene_id -ir {input.seq} -ig {input.ann} -o {output}"


rule reads:
    input:
        "ref/transcripts.chr{chrom}.fa"
    output:
        "reads/{sample}.chr{chrom}.1.fq",
        "reads/{sample}.chr{chrom}.2.fq"
    params:
        seed=lambda wildcards: hash(wildcards.sample)
    conda:
        "envs/wgsim.yaml"
    shell:
        "wgsim -S {params.seed} -N 1000 {input} {output}"
