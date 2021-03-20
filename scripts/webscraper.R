library(rvest)
library(dplyr)

url <- "https://www.kurashiru.com/recipes/7a90feb7-0542-4299-adb3-9339fb75f9d7"

content <- read_html(url)

title <- content %>%
  html_node(".title") %>%
  html_text()
cooking_time <- content %>%
  html_node(".cooking-time") %>%
  html_text()
