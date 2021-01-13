`%>%` <- dplyr::`%>%`
select <- dplyr::select
any_of <- dplyr::any_of

find_method <- function(generic, ...) {
	ch <- deparse(substitute(generic))
	f <- X <- function(x, ...) UseMethod("X")
	for(m in methods(ch)) assign(sub(ch, "X", m, fixed = TRUE), "body<-"(f, value = m))
	X(...)
} # https://stackoverflow.com/a/42742370/380403

# expect_same_colnames <- function(obs, exp, with_est = T, with_int = F) {
# 	browser()
# 	exp <- select(exp, -any_of(c('rule.list', 'rule.eval')))
#
# 	if (with_est == FALSE){
#
# 		exp <- select(exp, -any_of(c('estimate', 'conf.low', 'conf.high', 'y.level')))
#
# 	} else if (with_est == TRUE & with_int == FALSE) {
#
# 		exp <- select(exp, -any_of(c('conf.low', 'conf.high')))
#
# 	}
# browser()
# 	expect_same_colnames(obs, exp)
#
# }

expect_same_colnames <- function(obs, exp) {
	expect_equal(sort(colnames(obs)), sort(colnames(exp)))
}


perform_output_tests <- function(model, exp, is_discrete_out, tree_length_fun) {
	obs <- tidy_tree(model, add_estimates = F)
	obs.est <- tidy_tree(model, add_estimates = T)
	obs.int <- tidy_tree(model, add_estimate = T, add_interval = T)

	test_that(paste('the output number of rows with argument add_estimate = F for the', ifelse(is_discrete_out, 'discrete', 'continuous'), 'model is as expected'), {
		expect_equal(nrow(obs), tree_length_fun(model) - 1)
	})

	test_that(paste('the output number of rows with argument add_estimate = T for the', ifelse(is_discrete_out, 'discrete', 'continuous'), 'model is as expected'), {
		expect_equal(nrow(obs.est) / ifelse(is_discrete_out, 3, 1), tree_length_fun(model) - 1)
	})

	test_that(paste('the output colnames with argument add_estimate = F for the', ifelse(is_discrete_out, 'discrete', 'continuous'), 'model are as expected'), {
		exp <- select(exp, -any_of(c('rule.list', 'rule.eval', 'estimate', 'conf.low', 'conf.high', 'y.level')))

		expect_same_colnames(obs, exp)
	})

	test_that(paste('the output colnames with arguments add_estimate = T and add_interval = F for the', ifelse(is_discrete_out, 'discrete', 'continuous'), 'model are as expected'), {
		exp <- select(exp, -any_of(c('rule.list', 'rule.eval', 'conf.low', 'conf.high')))

		expect_same_colnames(obs.est, exp)
	})

	test_that(paste('the output colnames with arguments add_estimate = T and add_interval = T for the', ifelse(is_discrete_out, 'discrete', 'continuous'), 'model are as expected'), {
		exp <- select(exp, -any_of(c('rule.list', 'rule.eval')))

		expect_same_colnames(obs.int, exp)
	})

	test_that(paste('the output content for the', ifelse(is_discrete_out, 'discrete', 'continuous'), 'model is as expected'), {
		obs <- tidy_tree(model, add_interval = T)
		obs$rule.list <- tidy_tree(model, rule_as_text = F)$rule
		obs$rule.eval <- tidy_tree(model, eval_ready = T)$rule

		cols <- sort(colnames(exp))

		expect_equal(obs[, cols], exp[, cols])
	})
}

perform_method_tests <- function(method, object) {
	test_that('the chosen method is the expected one', {
		expect_identical(find_method(tidy_tree, object), method)
	})

	method <- get(method)

	test_that('the method argurments are compatible with the general specification', {
		exp <- formalArgs(tidy_tree)
		obs <- formalArgs(method)

		nms <- obs %in% exp
		expect_equal(obs[nms], exp)

	})
}

perform_stump_test <- function(tree_method) {
	test_that('a zero rows data frame is outputted for stump trees', {
		model <- tree_method(Sepal.Width ~ Species + Sepal.Length, data = iris[1,])

		expect_equal(nrow(suppressWarnings(tidy_tree(model))), 0)
		suppressWarnings(expect_warning(tidy_tree(model), 'Tree is only a stump'))
	})
}

perform_predictions_test <- function(model, model_data = NULL) {
	if (is.null(model_data)) model_data <- model.frame(model$terms, iris)

	is_discrete <- tidytrees:::is.discrete(model_data[,1])

	test_that(paste('predictions for the', ifelse(is_discrete, 'discrete', 'continous'), 'model are as expected'), {
		obs <- tidy_tree(model, eval_ready = T, add_interval = T)

		exp <- lapply(obs$id %>% unique, function(i) {
			rule <- obs$rule[obs$id == i]

			node.obs <- with(iris, model_data[,1][eval(str2expression(rule))])
			node.obs <- node.obs[!is.na(node.obs)]

			if (!is_discrete) {
				estimate = mean(node.obs)
				se <- sd(node.obs)/sqrt(length(node.obs))
				Z <- stats::qnorm(.95)

				ret <- data.frame(
					estimate,
					conf.low = estimate - Z * se,
					conf.high = estimate + Z * se
				)
			} else {

				ret <- table(node.obs) %>%
					lapply(binom.test, length(node.obs)) %>%
					lapply(broom::tidy) %>%
					dplyr::bind_rows() %>%
					dplyr::select(estimate, conf.low, conf.high) %>%
					dplyr::mutate_all(setNames, NULL) %>%
					dplyr::mutate(y.level = names(table(node.obs)))

				if (nrow(ret) == 2) ret <- ret[2,]
			}

			ret %>% dplyr::mutate(n.obs = length(node.obs))
		}) %>% dplyr::bind_rows() %>% as.data.frame()

		obs <- select(obs, any_of(c('n.obs', 'estimate', 'y.level')), matches('conf'))

		for (col in colnames(obs)) {
			expect_equal(obs[,col], exp[,col], label = col, expected.label = col)
		}

		cols <- sort(colnames(exp))
		expect_equal(obs[, cols], exp[, cols])

	})
}


