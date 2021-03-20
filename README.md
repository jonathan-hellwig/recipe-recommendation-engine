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
