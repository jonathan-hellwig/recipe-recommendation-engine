library(testthat)
source("/home/cmp/projects/recipe-recommendation-engine/scripts/webscraper.R")
test_that("Scraping links works", {
  expect_equal(length(scrape_recipe_links(1)), 30)
})
test_that("Test", {
            url <- "https://www.kurashiru.com/recipes/3365e1c3-f4e5-4de4-8b04-f1ad19e44f51"
            output <- scrape_recipes(url, "test.log")
            expect_equal(output[[1]][[1]][["recipe_name"]], "ホットケーキミックスで！さくさくメロンパン")
})
