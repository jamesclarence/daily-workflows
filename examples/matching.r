# from http://stackoverflow.com/questions/24965472/in-r-how-do-i-use-fuzzy-matching-to-search-for-multiple-patterns

survey <- c("Salem", "salem, ma","Manchester","Manchester-By-The-Sea")
master <- c("Beverly","Gloucester","Manchester-by-the-Sea","Nahant","Salem")

n.match <- function(pattern, x, ...) {
    matches <- numeric(length(pattern))
    for (i in 1:length(pattern)) {
       idx <- agrep(pattern[i],x,ignore.case=TRUE, max.distance = 2)
       matches[i] <- length(idx)
    }
    matches       
}
n.match(master,survey)
# [1] 0 0 1 0 2
