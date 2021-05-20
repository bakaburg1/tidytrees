#' Plug-in function for prediction estimates and confidence intervals
#'
#' This function provides maximum likelihood point estimates of the outcome for
#' each node in the tree (albeit it can be used with any vector of values). It
#' optionally also computes the confidence intervals around those estimates,
#' using a normal approximation \ifelse{html}{\out{<i>mean ± Z<sub>&alpha;</sub>
#' SE</i>}}{\eqn{mean ± Z_{\alpha} SE}} for continuous values and
#' `stats::binom.test()` exact binomial intervals for discrete (i.e.: character,
#' factor, logical) ones.
#'
#' @details The function is passed as the `est_fun` argument of `tidy_tree()`,
#'   but works also as stand-alone. This is a default estimation method
#'   Estimates can be extremely noisy in decision trees, especially in small
#'   terminal nodes; therefore more robust solutions (e.g. Bayesian regularized
#'   intervals) are a better choice.
#'
#' @param values Values of the outcome in a tree node.
#' @param add_interval Whether to compute confidence intervals.
#' @param interval_level Confidence level. Must be strictly greater than 0 and
#'   less than 1. Defaults to 0.95, which corresponds to a 95 percent confidence
#'   interval.
#'
#' @return A  tibble with the estimates and the interval boundaries, with
#'   differences based on the type of input:
#'
#'   \describe{ \item{Continuous values}{One row with the mean and optionally
#'   the confidence intervals of the mean} \item{Discrete values}{One row for
#'   each unique value, identified in the `y.level` column, with the value
#'   probability and the binomial confidence interval around the probability.}}
#'
#' @export
#'
#' @examples
#'
#' ## Stand alone usage
#' get_pred_estimates(iris$Species)
#' get_pred_estimates(iris$Sepal.Width)
#'
#'
#' ## Usage with `tidy_tree()`
#'
#' mod <- rpart::rpart(iris$Species ~ iris$Sepal.Length, iris)
#'
#' tidy_tree(mod, add_estimates = T, est_fun = get_pred_estimates, add_interval = T)
#' ## (actually est_fun = get_pred_estimates is redundant since it's the default)
#'
#'
#'
get_pred_estimates <- function(values, add_interval = FALSE, interval_level = 0.95) {

	if (any(is.na(values))) {
		warning('Missing values in the outcome. Will be removed')
		values <- values[!is.na(values)]
	}

	if (is.numeric(values)) {

		out <- data.frame(
			estimate = mean(values)
		)

		if (add_interval) {
			se <- sd(values)/sqrt(length(values))
			Z <- stats::qnorm(interval_level)

			out %>% dplyr::mutate(
				conf.low = estimate - Z * se,
				conf.high = estimate + Z * se
			)
		} else out

	} else if (is.discrete(values)) {

		# extract unique values
		if (is.factor(values)) lvls <- levels(values)
		else lvls <- sort(unique(values))

		if (length(lvls) == 2) lvls <- lvls[2] # if just two values, we remove the baseline since its estimates can be extracted doing 1 - estimates

		out <- lapply(lvls, function(lvl) {
			if (add_interval) {
				broom::tidy(stats::binom.test(sum(values %in% lvl), length(values), conf.level = interval_level)) %>%
					dplyr::select(estimate, conf.low, conf.high)
			} else {
				data.frame(estimate = mean(values %in% lvl))
			}
		}) %>% dplyr::bind_rows()

		names(out$estimate) <- NULL

		if (length(lvls) > 1) dplyr::mutate(out, y.level = lvls) else out

	} else stop('Values should be either numeric, factors, characters or logical.')
}
