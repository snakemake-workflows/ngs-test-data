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


rule reads:
    output:
        "reads/{sample}.chr{chrom}.1.fq",
        "reads/{sample}.chr{chrom}.2.fq"
    params:
        url=config["bam"],
        seed=lambda wildcards: abs(hash(wildcards.sample)) % 10000
    conda:
        "envs/samtools.yaml"
    shell:
        "samtools bam2fq -1 {output[0]} -2 {output[1]} "
        "<(samtools view -b -s{params.seed}.2 {params.url} chr{wildcards.chrom})"
