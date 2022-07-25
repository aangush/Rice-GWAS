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

# Transform ID data into rownames (for statgenGWAS)
data.geno <- data.geno %>% as.data.frame() %>% column_to_rownames("ID")

data.map <- data.frame(SNP=colnames(data.geno)) # create the object

# create the data.map object for GWAS
data.map <- data.map %>%
  separate(SNP, into=c("chr", "pos"), sep="_", remove=FALSE, convert=TRUE ) %>%
  column_to_rownames("SNP")

# create phenotype data 
data.pheno.small <- data.pheno %>%
  set_names(make.names(colnames(.))) %>%
  rename(genotype=NSFTVID) %>%
  select(genotype, where(is.numeric)) %>%
  as.data.frame() # for GWAS, need data frames, not tibbles ;()

# lastly, create a data frame of covariates
data.cv <- geno.pca.pop %>%
  as.data.frame() %>%
  column_to_rownames("ID")

# create the .gdata object -- combine the objects above into one
gData.rice <- createGData(geno=data.geno, map = data.map, pheno = data.pheno.small, covar = data.cv)

#recode the genotype data
gData.rice.recode <- gData.rice %>% codeMarkers(verbose = TRUE)

# Create a kinship matrix to help correct for pop. structure
data.kinship <- kinship(gData.rice.recode$markers)

# Now it is time to run the GWAS. This will be done in different ways to compare methods of population structure correction

# First, running the GWAS with no correction for pop. structure

#define a zero matrix
nullmat <- matrix(0, ncol=413,nrow=413, dimnames = dimnames(data.kinship))

# run the GWAS
gwas.noCorrection<- runSingleTraitGwas(gData = gData.rice.recode,
                                       traits = "Seed.length",
                                       kin = nullmat)
# examine results of first GWAS
summary(gwas.noCorrection)

plot(gwas.noCorrection, plotType = "qq") # View qq plot

plot(gwas.noCorrection, plotType = "manhattan") # View manhattan plot

# Run GWAS again, but include PCs for pop. structure correction
gwas.PCA <- runSingleTraitGwas(gData = gData.rice.recode,
                               traits = "Seed.length",
                               kin = nullmat,
                               covar = c("PC1", "PC2", "PC3", "PC4"))
# View results
summary(gwas.PCA)

plot(gwas.PCA, plotType = "qq")

plot(gwas.PCA, plotType = "manhattan")                      

# Now, run a GWAS and use a kinship matrix as pop. structure correction
gwas.K <- runSingleTraitGwas(gData = gData.rice.recode,
                             traits = "Seed.length",
                             kin = data.kinship)
# view the results
summary(gwas.K)

plot(gwas.K, plotType = "qq")

plot(gwas.K, plotType = "manhattan")

# using kinship matrix appears to be the best method so far for controlling for population structure





