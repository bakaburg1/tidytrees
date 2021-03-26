#' @describeIn tidy_tree Turns a classification/regression tree produced by
#'   [partykit::ctree()] into a tidy tibble. Also trees of class
#'   [`XML::XMLNode`] and [`RWeka::Weka_tree`] can be processed after conversion
#'   with `partykit::as.party()` (but results have not been tested yet).
#'
#' @export

tidy_tree.party <- function(tree, rule_as_text = TRUE, eval_ready = FALSE,
														add_estimates = TRUE, add_interval = FALSE,
														interval_level = 0.95,
														est_fun = tidytrees::get_pred_estimates) {

	if (length(tree) == 1) {
		warning('Tree is only a stump')
		return(data.frame(rule = character(), id = numeric(), n.obs = numeric(),
											depth = numeric(), terminal = logical()))
	}

	if (add_estimates == FALSE & add_interval == TRUE) {
		warning('"add_interval" is TRUE but add estimates is FALSE; no interval will be computed.')
	}

	## strangely nodeapply is faster than lapply!!
	ret <- partykit::nodeapply(tree, partykit::nodeids(tree), function(x) {

		split <- partykit::split_node(x)

		if (length(x) > 0) {
			slabs <- partykit::character_split(split, data = tree$data, digits = 3)
			rule <- if (any(stringr::str_detect(slabs$levels, '[<>]'))) {
				paste(slabs$name, slabs$levels)
			} else {
				paste(slabs$name, "in", slabs$levels)
			}
			kids <- partykit::kids_node(x)

			data.frame(
				parent = partykit::id_node(x),
				rule,
				id = sapply(kids, id_node),

				## computing n.obs and terminal here is faster than using sapply over the ids outside

				# n.obs = sapply(kids, function(kid) { # slightly slower
				# 	if (is.null(kid$info$nobs)) NA else kid$info$nobs
				# }) %>% {
				# 	.[is.na(.)] <- x$info$nobs - .[!is.na(.)]
				# 	.
				# },
				n.obs = {

					kids_obs <- c(
						if (is.null(kids[[1]]$info$nobs)) NA else kids[[1]]$info$nobs,
						if (is.null(kids[[2]]$info$nobs)) NA else kids[[2]]$info$nobs
					)

					if (all(is.na(kids_obs))) {
						# Sometimes both kids node don't have info on n.obs, so the node observations need to be extracted (expensive).
						# I can't understand how partykit::print solves this apparent randomness
						kids_obs <- partykit::data_party(tree, id = sapply(kids, id_node)) %>% sapply(nrow)
					} else { # sometimes instead n.obs is only in one of the kids
						kids_obs[is.na(kids_obs)] <- x$info$nobs - kids_obs[!is.na(kids_obs)]
					}

					kids_obs
				},
				#terminal = sapply(kids, is.terminal) # slightly slower
				terminal = c(
					partykit::is.terminal(kids[[1]]),
					partykit::is.terminal(kids[[2]])
				)
			)
		}

	}) %>% dplyr::bind_rows() %>%
		dplyr::mutate(

			rule = if (eval_ready) {
				rule %>%
					stringr::str_replace(' in ', ' %in% ') %>%
					stringr::str_replace_all(c(', ' = '", "', '%\\s+' = '% c("', '(\\D)$' = '\\1")'))
			} else rule,

			rule = sapply(1:dplyr::n(), function(i) {
				cur_id = id[i]

				rule.vec <- rule[i]

				while (cur_id > 2) {
					cur_id <- parent[id == cur_id]
					rule.vec <- c(rule[id == cur_id], rule.vec)
				}

				if (rule_as_text) paste(rule.vec, collapse = ' & ') else rule.vec

			}),

			depth = if (rule_as_text) {
				stringr::str_count(rule, stringr::fixed('&')) + 1
			} else sapply(rule, length),
		)

	if (add_estimates) {
		ret <- lapply(ret$id, function(i) {
			data.frame(
				ret[ret$id == i,],
				est_fun(tree[i]$fitted$`(response)`,add_interval = add_interval, interval_level = interval_level),
				row.names = NULL
			)
		}) %>% dplyr::bind_rows()
	}

	dplyr::arrange(ret, id) %>% dplyr::select(-parent) %>%
		dplyr::tibble()
}
