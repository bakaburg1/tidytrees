#' @describeIn tidy_tree Turn a classification/regression tree produced by
#'   [rpart::rpart()] into a tidy tibble. At the moment, only the `anova` and
#'   `class` methods are fully supported: other methods may work but users need
#'   to ensure that the fit details are correct.
#'
#' @export

tidy_tree.rpart <- function(tree, rule_as_text = TRUE, eval_ready = FALSE,
														add_estimates = TRUE, add_interval = FALSE,
														interval_level = 0.95,
														est_fun = tidytrees::get_pred_estimates) {

	# Could just use tidy_tree(as.party(tree)) here, but it would be noticeably slower for big or multiple trees

	if (tree$method %nin% c('anova', 'class')) warning('Prediction estimates are fully supported only for anova and classification trees. Intepret fit results for other models with care.')

	if (nrow(tree$frame) == 1) {
		warning('Tree is only a stump')
		return(data.frame(rule = character(), id = numeric(), n.obs = numeric(),
											depth = numeric(), terminal = logical()))
	}

	if (add_estimates == FALSE & add_interval == TRUE) {
		warning('"add_interval" is TRUE but add estimates is FALSE; no interval will be computed.')
	}

	ret <- tree$frame[-1,] %>%
		tibble::rownames_to_column('id') %>%
		dplyr::mutate(id = as.numeric(id)) %>%
		dplyr::transmute(
			rule = path.rpart(tree, id, print.it = FALSE) %>%
				lapply(function(node.rules) { # add spaces around equal/greater/less signs

					stringr::str_replace_all(node.rules[-1], c(
						' ' = '',
						'(=|[<>]=?)' = ' \\1 ' # add spaces around comparators
					))

				}),
			id,
			n.obs = n,
			depth = rpart:::tree.depth(id) + 1,
			terminal = var == '<leaf>'
		)

	if (add_estimates) {
		edges <- rpart:::descendants(c(1, ret$id))

		y <- tree$y

		if (tree$method == 'class') {
			y <- factor(y, labels = attr(tree, "ylevels"))
		}

		ret <- lapply(1:nrow(ret), function(i) {
			cur_node <- ret[i,]

			relevant_nodes <- which(edges[i + 1,])

			obs <- y[tree$where %in% relevant_nodes]

			estimates <- est_fun(obs, add_interval = add_interval,
													 interval_level = interval_level)

			data.frame(cur_node, estimates, row.names = NULL)
		}) %>% dplyr::bind_rows()

	}

	if (eval_ready) {
		ret$rule <- sapply(ret$rule, function(rules) {

			stringr::str_replace_all(rules, c(
				' = ' = ' %in% ',
				',' = '", "',
				'% (.*)' = '% "\\1"',
				',(.*)' = ',\\1)',
				'% (.+),' = '% c(\\1,'
			)) %>% paste(collapse = ' & ')
		})
	} else if (rule_as_text) {
		ret$rule <- sapply(ret$rule, paste, collapse = ' & ')
	}

	rownames(ret) <- NULL

	ret
}
