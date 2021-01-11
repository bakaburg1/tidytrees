#' Negation of %in% function
`%nin%` <- function (x, table) {
	!(match(x, table, nomatch = 0L) > 0L)
}

#' Test if x is either a character, a factor or a logical value
is.discrete <- function(x) {
	is.character(x) | is.factor(x) | is.logical(x)
}
