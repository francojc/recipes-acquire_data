
# ABOUT -------------------------------------------------------------------

# Description: This script collects data from the web and stores it on disk
# Usage: Only an internet connection is required. Data collected is stored
# in the `data/original/` directory. 
# Author: Jerid Francom
# Date: October 1, 2017

# SETUP -------------------------------------------------------------------

# Script-specific options or packages
pacman::p_load(tidyverse, gutenbergr, rvest, stringr)

# Load custom functions for this project
source(file = "functions/acquire_functions.R")

# RUN ---------------------------------------------------------------------

# _ REPOSITORIES ----------------------------------------------------------

# Download Switchboard Corpus sample (SCs) --------------------------------

# SCs sample found at: http://www.nltk.org/nltk_data/

# Download corpus
get_zip_data(url = "https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/switchboard.zip", target_dir = "data/original/scs/")

# Download Santa Barbara Corpus (SBC) -------------------------------------

# SBC found at: http://www.linguistics.ucsb.edu/research/santa-barbara-corpus

# Download corpus transcriptions
get_zip_data(url = "http://www.linguistics.ucsb.edu/sites/secure.lsit.ucsb.edu.ling.d7/files/sitefiles/research/SBC/SBCorpus.zip", target_dir = "data/original/sbc/transcriptions/")

# Download corpus meta-data
get_zip_data(url = "http://www.linguistics.ucsb.edu/sites/secure.lsit.ucsb.edu.ling.d7/files/sitefiles/research/SBC/metadata.zip", target_dir = "data/original/sbc/meta-data/")

# _ PACKAGE INTERFACES ----------------------------------------------------

# Download text from Project Gutenberg: subject PR ------------------------

# Download Project Gutenberg text for subject 'PR' (English Literature)
# and then write this dataset to disk in .csv format
get_gutenberg_subject(subject = "PR", 
                    target_file = "data/original/gutenberg_works_pr.csv")

# Download text from Project Gutenberg: subject PQ ------------------------

# Download Project Gutenberg text for subject 'PQ' (American Literature)
# and then write this dataset to disk in .csv format
get_gutenberg_subject(subject = "PQ", 
                    target_file = "data/original/gutenberg_works_pq.csv")

# _ WEB SCRAPING ----------------------------------------------------------

# Scrape archives of the Spanish news site elpais.com by tag
# To search for valid tags: https://elpais.com/tag/listado/

# Scrape text from El País by tag: `politica` -----------------------------

download_elpais_tag(tag_name = "politica", 
                    target_file = "data/original/elpais/political_articles.csv")

# Scrape text from El País by tag: `gastronomia` ---------------------------

download_elpais_tag(tag_name = "gastronomia", 
                    target_file = "data/original/elpais/gastronomy_articles.csv")

# LOG ---------------------------------------------------------------------

# Any descriptives that will be helpful to understand the results of this
# script and how it contributes to the aims of the project

# Log the directory structure of the Santa Barbara Corpus
system(command = "tree data/original/sbc >> log/data_original_sbc.log")
# Log the directory structure of the Switchboard Corpus sample
system(command = "tree data/original/scs >> log/data_original_scs.log")

# CLEAN UP ----------------------------------------------------------------

# Remove all current environment variables
rm(list = ls())
