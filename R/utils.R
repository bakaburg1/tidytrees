#' Negation of %in% function
`%nin%` <- function (x, table) {
	!(match(x, table, nomatch = 0L) > 0L)
}

#' Test if x is either a character, a factor or a logical value
is.discrete <- function(x) {
	is.character(x) | is.factor(x) | is.logical(x)
}

#' Simplify rules to the minimal defining set
#'
#' Tree algorithms returns nested, redundant rule sets. This function simplify
#' the rules keeping the shortest condition set required to univocally identify
#' the partition.
#'
#' @param rules A vector of rules or a list of rule components.
#'
#' @return A vector or a list, based on the input, with the smallest set of
#'   rules that identifies a partition.
#'
#' @export
#'
#' @examples
#'
#' tree <- ctree(Sepal.Length ~ Species + Sepal.Width, iris)
#' rules <- tidy_tree()
#' simplify_rules(rules$rule)
#'
#' ## Works also with a list of conditions
#'
#' #' rules <- tidy_tree(rule_as_text = FALSE)
#' simplify_rules(rules$rule)
#'

simplify_rules <- function(rules) {
	if (length(rules) == 0 || is.null(rules)) return(rules)

	sapply(rules, function(rule) {

		if (all(rule == '') | all(is.na(rule))) return(NA)

		if (length(rule) == 1) {
			components <- stringr::str_split(rule, ' & ') %>% unlist
		} else components <- rule

		vars <- unique(stringr::str_extract(components, '.* [<>%=in]+'))
		ind <- sapply(vars, function(v) tail(which(grepl(x = components, pattern = v, fixed = TRUE)), 1))

		components <- sort(components[ind])

		if (length(rule) == 1) paste(components, collapse = ' & ') else components
	}) %>% setNames(NULL)
}
