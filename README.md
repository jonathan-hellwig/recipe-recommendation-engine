# A recommendation engine for japanese recipes
The goal of this project is to create a recommendation engine for japanese recipes where you can specify certain ingredients and recipe characteristics. These characteristics include the time to prepare, ingredients costs and similarity to previous recipes selecte by the user. 
The project is divided into the following steps:
1. Get the data using a web scraping application
1. Set up a server that automatically runs the web scraping application
1. Set up a data base on the server that collects the data obtained in the previous step
1. Design a recommendation algorithm in R
1. Set up a up a shiny application for easy usage of the recommendation engine

# Getting the data
## Data specification
The website used to obtain japanese recipes is [クラシル](https://www.kurashiru.com/). A recipe has the following elements (e.g. [Recipe for melon bread](https://www.kurashiru.com/recipes/3365e1c3-f4e5-4de4-8b04-f1ad19e44f51)):
1. Title
1. Short introductary text
1. Preparation time in minutes
1. Cost for ingredients in Yen
1. List of Ingredients and amounts
1. Number of portions
1. Instructions
1. Special remark
1. Attempts by user of the side including a picture and a short text
1. Questions
1. Categories
1. Keywords

The recipes on クラシル all have the same structure. Therefore, in order to obtain every recipe it is possible to create a scraping function for a single recipe and then iterate over all recipes. On クラシル there is no list of all recipes. A possible approach is to iterate over all categories of recipes and scrape each recipe of that category. This approach might lead to some recipes to be included multiple times because each recipe belongs to several categories. To avoid that problem a unique id is assigned to each recipe. Before adding a new recipe to the data base the id is checked and if the data base already contains the recipe scraping is aborted.

The data of each recipe page is divided into four data frames:
1. Id, Recipe name, preparation time, cost of ingredients, Instructions
1. Id, Ingredients, quantities
1. Id, User name, Date, Comments
1. Id, Categories

The reason for dividing the data into five different data frames is to preserve the [tidy data](https://vita.had.co.nz/papers/tidy-data.html) format. In later stages of the project this format will simplify data analysis greatly. 
# Setting up the server
In this project I decided to use a google compute engine since I already had some familiarity with their services. The reasons for running the scraping script on a server are twofold. 
1. Scraping over 20000 recipes takes several day to scrape with the necessary delay specified by the robots.txt. 
1. Choosing a server in Japan greatly reduces latency. 
One important requirement for running the script on a server is adequate logging and error handling. I decided to use the packages [log4r](https://cran.r-project.org/web/packages/log4r/index.html) for logging and used [purrr's](https://purrr.tidyverse.org/) possibly for error handling.
# Project status
21.03.21 Finished scraping script for a single recipe. The next step is to apply the script to a list of recipes.

24.03.21 Added functionality to iterate over all recipes listed on クラシル and combine all results into a single list. The scraping for the comments is still not working. Since there are over 20000 recipes on クラシル the whole scraping process takes approximatly two days if sufficient delay between scraping attemps is added.

04.04.21 Added a python script that uses selenium to scrape content generated by javascript. Previously the script was only able to obtain static content. Therefore, comments are now correctly added to the datafarme. Furthermore, a postgresql database was and function to write to it was created. 

08.04.12 Added error handling and a timeout value to the main script. Refactored code to be more reusable.
# Credit
1. The resource I mainly used to learn about web scraping in R is a [blog post](https://www.r-bloggers.com/2020/05/intro-to-polite-web-scraping-of-soccer-data-with-r/) by R by R(yo). The post goes into great detail on how to used the polite package to do ethical web scraping in R.
1. The [github page](https://github.com/dmi3kno/polite) of the polite package also provided some useful examples.
1. To learn about the connection between sql and R I used a [resource](https://db.rstudio.com/dplyr/) by RStudio.
