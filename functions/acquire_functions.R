
# ABOUT -------------------------------------------------------------------

# Functions to facilitate acquiring data

# Direct downloads --------------------------------------------------------

get_zip_data <- function(url, target_dir) {
  # Function: to download and decompress a .zip file to a target directory
  
  # Check to see if the data already exists
  if(!dir.exists(target_dir)) { # if data does not exist, download/ decompress
    cat("Creating target data directory \n") # print status message
    dir.create(path = target_dir, recursive = TRUE, showWarnings = FALSE) # create target data directory
    cat("Downloading data... \n") # print status message
    temp <- tempfile() # create a temporary space for the file to be written to
    download.file(url = url, destfile = temp) # download the data to the temp file
    unzip(zipfile = temp, exdir = target_dir, junkpaths = TRUE) # decompress the temp file in the target directory
    cat("Data downloaded! \n") # print status message
  } else { # if data exists, don't download it again
    cat("Data already exists \n") # print status message
  }
}

# APIs --------------------------------------------------------------------

get_gutenberg_subject <- function(subject, target_file, sample_size = 10) {
  # Function: to download texts from Project Gutenberg with 
  # a specific LCC subject and write the data to disk.
  
  # Check to see if the data already exists
  if(!file.exists(target_file)) { # if data does not exist, download and write
    target_dir <- dirname(x) # generate target directory for the .csv file
    dir.create(path = target_dir, recursive = TRUE, showWarnings = FALSE) # create target data directory
    cat("Downloading data... \n") # print status message
    # Select all records with a particular LCC subject
    ids <- 
      filter(gutenberg_subjects, 
             subject_type == "lcc", subject == subject) # select subject
    # Select only those records with plain text available
    set.seed(123) # make the sampling reproducible
    ids_sample <- 
      filter(gutenberg_metadata, 
             gutenberg_id %in% ids$gutenberg_id, # select ids in both data frames 
             has_text == TRUE) %>% # select those ids that have text
      sample_n(sample_size) # sample N works (default N = 10)
    # Download sample with associated `author` and `title` metadata
    works_sample <- 
      gutenberg_download(gutenberg_id = ids_sample$gutenberg_id, 
                         meta_fields = c("author", "title"))
    # Write the dataset to disk in .csv format
    write_csv(works_sample, path = target_file)
    cat("Data downloaded! \n") # print status message
  } else { # if data exists, don't download it again
    cat("Data already exists \n") # print status message
  }
}


# Web scraping ------------------------------------------------------------

# Functions for scraping text by tag on the Spanish news site elpais.com

get_archive_pages <- function(tag_name, sample_size) {
  # Function: Scrape tag main page and return selected number of archive pages
  url <- paste0("https://elpais.com/tag/", tag_name)
  html <- read_html(url) # load html from selected url
  pages_available <- 
    html %>% # pass html
    html_node("li.paginacion-siguiente a") %>% # isolate 'next page' link
    html_attr("href") %>% # extract 'next page' link
    str_extract("\\d+$") %>% # extract the numeric value (num pages of links) in link
    as.numeric() + 1 # covert to a numeric vector and add 1 (to include first page)
  cat(pages_available, "pages available for the", tag_name, "tag.\n")
  archive_pages <- paste0(url, "/a/", (pages_available - (sample_size - 1)):pages_available) # compile urls
  cat(sample_size, "pages selected.\n")
  return(archive_pages)
}

get_content_links <- function(url) {
  # Function: Scrape the content links from a tag archive page
  html <- read_html(url) # load html from selected url
  urls <- 
    html %>% # pass html
    html_nodes("h2.articulo-titulo a") %>% # isolate links
    html_attr("href") %>% # extract urls
    str_replace(pattern = "//", replacement = "https://") # create valid urls
  cat(length(urls),"content links scraped from tag archives.\n")
  return(urls)
}

get_content <- function(url) {
  # Function: Scrape the title, author, date, and text from a provided
  # content link. Return as a tibble/data.frame
  cat("Scraping:", url, "\n")
  html <- read_html(url) # load html from selected url
  
  # Title
  title <- 
    html %>% # pass html
    html_node("h1.articulo-titulo") %>% # isolate title
    html_text(trim = TRUE) # extract title and trim whitespace
  
  # Author
  author <- 
    html %>% # pass html
    html_node("span.autor-nombre") %>% # isolate author
    html_text(trim = TRUE) # extract author and trim whitespace
  
  # Date
  date <- 
    html %>% # pass html
    html_nodes("div.articulo-datos time") %>% # isolate date
    html_attr("datetime") # extract date
  
  # Text
  text <- 
    html %>% # pass html
    html_nodes("div.articulo-cuerpo p") %>% # isolate text by paragraph
    html_text(trim = TRUE) # extract paragraphs and trim whitespace
  
  # Check to see if the article is text based
  # - only one paragraph suggests a non-text article (cartoon/ video/ album)
  if (length(text) > 1) { 
    # Create tibble/data.frame
    return(tibble(url, title, author, date, text, paragraph = (1:length(text))))
  } else {
    message("Non-text based article. Link skipped.")
    return(NULL)
  }
}

write_content <- function(content, target_file) {
  # Function: Write the tibble content to disk. Create the directory if
  # it does not already exist.
  target_dir <- dirname(target_file) # identify target file directory structure
  dir.create(path = target_dir, recursive = TRUE, showWarnings = FALSE) # create directory
  write_csv(content, target_file) # write csv file to target location
  cat("Content written to disk!\n")
}

download_elpais_tag <- function(tag_name, sample_size, target_file, force = FALSE) {
  # Function: Download articles from elpais.com based on tag name. Select
  # number of archive pages to consult, then scrape and write the content 
  # to disk. If the target file exists, do not download again.
  if(!file.exists(target_file) | force == TRUE) {
    get_archive_pages(tag_name, sample_size) %>% # select tag archive pages
      map(get_content_links) %>% # get content links from pages sampled
      combine() %>% # combine the results as a single vector
      map(get_content) %>% # get the content for each content link
      bind_rows() %>% # bind the results as a single tibble
      write_content(target_file) # write content to disk
  } else {
    cat("Data already downloaded!\n")
  }
}
