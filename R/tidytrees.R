#' Turn a classification/regression tree object into a tidy tibble
#'
#' Takes a classification/regression tree (usually a list) and returns a
#' [tibble::tibble()] with a row for each node including the set of additive
#' rules necessary to identify it. Furthermore, node characteristics and fit
#' details are described.
#'
#' @param tree A tree object.
#' @param rule_as_text Whether to represent the rules as a string or a vector.
#' @param eval_ready Converts the rules into R compatible logical expressions
#'   ready to use for data filtering purposes. If `FALSE`, the rules are kept as
#'   originally defined in each class.
#' @param add_estimates Add predicted values at each node, as computed by the
#'   function passed to `est_fun`.
#' @param add_interval Logical indicating whether or not to include an
#'   estimation interval, as computed by `est_fun` in the tidied output.
#'   Defaults to `FALSE`.
#' @param interval_level The interval level to use for the estimation interval
#'   if `add_interval = TRUE`. Must be strictly greater than 0 and less than 1.
#'   Defaults to 0.95.
#' @param est_fun Function to estimate node predictions and intervals. Must
#'   expose three mandatory arguments: `values` which receive the observations
#'   in a node, and `add_interval` and `interval_level` which get inherited from
#'   `tidy_tree()`. Check [`get_pred_estimates`] as a prototype.
#' @param ... Method specific arguments. Not used at the moment.
#'
#' @return A tibble with a row for each node with its identifying rule, the node
#'   id (as stored in the tree object), the number of observations related to
#'   the node, whether the node is terminal (a leaf), and the node depth. The
#'   depth is counted starting from the children of the root node which are
#'   considered at depth 1. The root node is ignored in the output. If
#'   `add_estimates = TRUE`, prediction estimates (optionally with intervals)
#'   are added to each node, as defined by the function passed to the `est_fun`
#'   argument.
#'
#'
#' @importFrom dplyr %>%
#' @export
#'
#' @examples
#'
#' mod <- rpart(iris$Sepal.Length ~ iris$Species)
#'
#' tidy_tree(mod)
#'
#' ## Adding confidence intervals
#'
#' tidy_tree(mod, add_interval = TRUE)
#'
tidy_tree <- function(tree, rule_as_text = TRUE, eval_ready = FALSE,
											 add_estimates = TRUE, add_interval = FALSE, interval_level = 0.95,
											 est_fun = tidytrees::get_pred_estimates)
{
	UseMethod("tidy_tree")
}
