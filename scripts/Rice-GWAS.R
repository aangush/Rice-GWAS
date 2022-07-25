library(tidyverse)
library(statgenGWAS)

# Load data from the previous analysis
load("../../Rice-PCA-SNPs/output/data_from_SNP_lab.Rdata")


# Join the PCs, population assignments, and phenotype data
pheno.geno.pca.pop <- left_join(geno.pca.pop, data.pheno, by=c("ID" = "NSFTVID"))

# get rid of spaces in the phenotype
colnames(pheno.geno.pca.pop) <- make.names(colnames(pheno.geno.pca.pop))

# Examine one of the phenotypes, I chose seed.Length
pl <- pheno.geno.pca.pop %>% ggplot(mapping=aes(x=Seed.length))
pl <- pl + labs(title="Histogram of Seed.length")
pl <- pl + geom_histogram(fill="darkblue")
pl

pl2 <- pheno.geno.pca.pop %>% ggplot(mapping=aes(x=Seed.length))
pl2 <- pl2 + labs(title="Seed.length faceted by assigned population")
pl2 <- pl2 + facet_wrap(facets= ~ assignedPop )
pl2 <- pl2 + geom_histogram(fill="blue")
pl2

pl3 <- pheno.geno.pca.pop %>% ggplot(mapping=aes(x=Seed.length))
pl3 <- pl3 + labs(title="Seed.length faceted by Region")
pl3 <- pl3 + facet_wrap(facets= ~ Region )
pl3 <- pl3 + geom_histogram(fill="darkviolet")
pl3

# Create a function to calculate sem, and investigate how mean seed length may (or may not)
# vary by region
# Standard error of the mean function
sem <- function(x, na.rm=TRUE) {
  if(na.rm) x <- na.omit(x)
  sd(x)/sqrt(length(x))
}

# Calculate the means and standard errors of the means of seed.Length for different regions
pheno.geno.pca.pop %>% group_by(Region) %>% 
  summarize(mean.seed.l=mean(Seed.length,na.rm=T),
            sem.seed.l=sem(Seed.length)
  ) %>%
  arrange(desc(mean.seed.l))

# perform an ANOVA on seed length to investigate if mean seed length varies significantly by region
aovsl <- aov(Seed.length ~ Region, data=pheno.geno.pca.pop)
summary(aovs1)


# Through the ANOVA above, we can conclude that Seed length varies significantly by region.

# Now it would be good to check if mean seed length varies significantly by fastStructure population assignment.
pheno.geno.pca.pop %>% group_by(assignedPop) %>% summarize(mean.Seed.length=mean(Seed.length, na.rm = T), sem.Seed.length=sem(Seed.length)) %>%
  arrange(desc(mean.Seed.length))

aov2 <- aov(Seed.length ~ assignedPop, data=pheno.geno.pca.pop)
summary(aov2)

# This analysis reveals that seed length does vary significantly by assigned population, suggesting that population structure could be a problem in a future GWAS

# Time to prepare GWAS data


# Load Genotype data
Sys.setenv(VROOM_CONNECTION_SIZE="500000") # needed because the lines in this file are long.

data.geno <- read_csv("../../Rice-PCA-SNPs/input/Rice_44K_genotypes.csv.gz",
                      na=c("NA","00"))  %>%
  rename(ID=`...1`, `6_17160794` = `6_17160794...22252`) %>% 
  select(-`6_17160794...22253`)


 














