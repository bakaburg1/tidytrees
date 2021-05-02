
library(rpart)

get_tree_length <- function(model) nrow(model$frame)

perform_n.obs_test <- function(model, model_type) {
	test_that(paste('the number of observations per node for the', model_type, 'model are correct'), {
		obs <- tidy_tree(model, add_estimates = F)
		exp <- model$frame[-1,]

		expect_equal(obs$n.obs, exp[as.character(obs$id),]$n)
	})
}


# General testing ---------------------------------------------------------

perform_method_tests('tidy_tree.rpart', rpart(Species ~ Sepal.Width + Sepal.Length, data = iris))

test_that('the rules are as in the original tree', {
	mod <- rpart(Species ~ Sepal.Width + Sepal.Length, data = iris)

	exp <- path.rpart(mod, rownames(mod$frame)[-1], print.it = F) %>%
		lapply(function(node.rules) { # add spaces around equal/greater/less signs

			stringr::str_replace_all(node.rules[-1], c(
				' ' = '',
				'(=|[<>]=?)' = ' \\1 ' # add spaces around comparators
			))

		}) %>% setNames(NULL)

	obs <- tidy_tree(mod, rule_as_text = F, add_estimates = F)$rule

	expect_equal(obs, exp)
})

test_that('all nodes are included', {
	mod <- rpart(Species ~ Sepal.Width + Sepal.Length, data = iris)

	obs <- tidy_tree(mod)

	expect_setequal(obs$id, rownames(mod$frame)[-1])
})

perform_stump_test(rpart)

test_that('the string rule simplification gives the expected output', {

	mod <- rpart(Sepal.Length ~ Species + Sepal.Width, iris)

	obs <- tidy_tree(mod, eval_ready = F)$rule %>% simplify_rules()

	exp <- c("Species = setosa", "Sepal.Width < 3.25 & Species = setosa",
					 "Sepal.Width >= 3.25 & Species = setosa", "Species = versicolor,virginica",
					 "Species = versicolor", "Sepal.Width < 2.75 & Species = versicolor",
					 "Sepal.Width >= 2.75 & Species = versicolor", "Sepal.Width < 3.05 & Sepal.Width >= 2.75 & Species = versicolor",
					 "Sepal.Width >= 3.05 & Species = versicolor", "Species = virginica",
					 "Sepal.Width < 2.85 & Species = virginica", "Sepal.Width >= 2.85 & Species = virginica")

	expect_identical(obs, exp)
})

test_that('the list rule simplification gives the expected output', {

	mod <- rpart(Sepal.Length ~ Species + Sepal.Width, iris)

	obs <- tidy_tree(mod, eval_ready = F, rule_as_text = F)$rule %>% simplify_rules()

	exp <- list("Species = setosa", c("Sepal.Width < 3.25", "Species = setosa"
	), c("Sepal.Width >= 3.25", "Species = setosa"), "Species = versicolor,virginica",
	"Species = versicolor", c("Sepal.Width < 2.75", "Species = versicolor"
	), c("Sepal.Width >= 2.75", "Species = versicolor"), c("Sepal.Width < 3.05",
																												 "Sepal.Width >= 2.75", "Species = versicolor"), c("Sepal.Width >= 3.05",
																												 																									"Species = versicolor"), "Species = virginica", c("Sepal.Width < 2.85",
																												 																																																		"Species = virginica"), c("Sepal.Width >= 2.85", "Species = virginica"
																												 																																																		))

	expect_identical(obs, exp)
})

# Discrete model testing -------------------------------------------------

mod.discr <- rpart(Species ~ Sepal.Width + Sepal.Length, data = iris)

# mod.discr %>% tidy_tree(add_interval = T) %>% dput()

mod.discr.exp <- structure(
	list(
		rule = c("Sepal.Length < 5.45", "Sepal.Length < 5.45",
						 "Sepal.Length < 5.45", "Sepal.Length < 5.45 & Sepal.Width >= 2.8",
						 "Sepal.Length < 5.45 & Sepal.Width >= 2.8",
						 "Sepal.Length < 5.45 & Sepal.Width >= 2.8",
						 "Sepal.Length < 5.45 & Sepal.Width < 2.8",
						 "Sepal.Length < 5.45 & Sepal.Width < 2.8",
						 "Sepal.Length < 5.45 & Sepal.Width < 2.8",
						 "Sepal.Length >= 5.45",
						 "Sepal.Length >= 5.45", "Sepal.Length >= 5.45",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width >= 3.1",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width >= 3.1",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width >= 3.1",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width < 3.1",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width < 3.1",
						 "Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width < 3.1",
						 "Sepal.Length >= 5.45 & Sepal.Length >= 6.15",
						 "Sepal.Length >= 5.45 & Sepal.Length >= 6.15",
						 "Sepal.Length >= 5.45 & Sepal.Length >= 6.15"),
		rule.list = list("Sepal.Length < 5.45", "Sepal.Length < 5.45", "Sepal.Length < 5.45",
										 c("Sepal.Length < 5.45", "Sepal.Width >= 2.8"), c("Sepal.Length < 5.45", "Sepal.Width >= 2.8"), c("Sepal.Length < 5.45", "Sepal.Width >= 2.8"),
										 c("Sepal.Length < 5.45", "Sepal.Width < 2.8"), c("Sepal.Length < 5.45", "Sepal.Width < 2.8"), c("Sepal.Length < 5.45", "Sepal.Width < 2.8"),
										 "Sepal.Length >= 5.45", "Sepal.Length >= 5.45", "Sepal.Length >= 5.45",
										 c("Sepal.Length >= 5.45", "Sepal.Length < 6.15"), c("Sepal.Length >= 5.45", "Sepal.Length < 6.15"), c("Sepal.Length >= 5.45", "Sepal.Length < 6.15"),
										 c("Sepal.Length >= 5.45", "Sepal.Length < 6.15", "Sepal.Width >= 3.1"), c("Sepal.Length >= 5.45", "Sepal.Length < 6.15", "Sepal.Width >= 3.1"), c("Sepal.Length >= 5.45", "Sepal.Length < 6.15", "Sepal.Width >= 3.1"),
										 c("Sepal.Length >= 5.45", "Sepal.Length < 6.15", "Sepal.Width < 3.1"), c("Sepal.Length >= 5.45", "Sepal.Length < 6.15", "Sepal.Width < 3.1"), c("Sepal.Length >= 5.45", "Sepal.Length < 6.15", "Sepal.Width < 3.1"),
										 c("Sepal.Length >= 5.45", "Sepal.Length >= 6.15"), c("Sepal.Length >= 5.45", "Sepal.Length >= 6.15"), c("Sepal.Length >= 5.45", "Sepal.Length >= 6.15")),
		rule.eval = c("Sepal.Length < 5.45", "Sepal.Length < 5.45",
									"Sepal.Length < 5.45", "Sepal.Length < 5.45 & Sepal.Width >= 2.8",
									"Sepal.Length < 5.45 & Sepal.Width >= 2.8", "Sepal.Length < 5.45 & Sepal.Width >= 2.8",
									"Sepal.Length < 5.45 & Sepal.Width < 2.8", "Sepal.Length < 5.45 & Sepal.Width < 2.8",
									"Sepal.Length < 5.45 & Sepal.Width < 2.8", "Sepal.Length >= 5.45",
									"Sepal.Length >= 5.45", "Sepal.Length >= 5.45", "Sepal.Length >= 5.45 & Sepal.Length < 6.15",
									"Sepal.Length >= 5.45 & Sepal.Length < 6.15", "Sepal.Length >= 5.45 & Sepal.Length < 6.15",
									"Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width >= 3.1",
									"Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width >= 3.1",
									"Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width >= 3.1",
									"Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width < 3.1",
									"Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width < 3.1",
									"Sepal.Length >= 5.45 & Sepal.Length < 6.15 & Sepal.Width < 3.1",
									"Sepal.Length >= 5.45 & Sepal.Length >= 6.15", "Sepal.Length >= 5.45 & Sepal.Length >= 6.15",
									"Sepal.Length >= 5.45 & Sepal.Length >= 6.15"),
		id = c(2, 2, 2, 4, 4, 4, 5, 5, 5, 3, 3, 3, 6, 6, 6, 12, 12, 12, 13, 13, 13, 7, 7, 7),
		n.obs = c(52L, 52L, 52L, 45L, 45L, 45L, 7L, 7L, 7L, 98L, 98L, 98L, 43L, 43L, 43L, 7L, 7L, 7L, 36L, 36L, 36L, 55L, 55L, 55L),
		depth = c(1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 2, 2, 2),
		terminal = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
		estimate = c(0.865384615384615, 0.115384615384615, 0.0192307692307692,
								 0.977777777777778, 0.0222222222222222,
								 0, 0.142857142857143,
								 0.714285714285714, 0.142857142857143,
								 0.0510204081632653, 0.448979591836735,
								 0.5, 0.116279069767442,
								 0.651162790697674, 0.232558139534884,
								 0.714285714285714, 0.285714285714286,
								 0, 0, 0.722222222222222,
								 0.277777777777778, 0,
								 0.290909090909091, 0.709090909090909),
		conf.low = c(0.742121414960492, 0.0435412039886871, 0.000486762415492083,
								 0.882295668581706, 0.000562459715402258, 0, 0.00361029686190059,
								 0.290420863737343, 0.00361029686190059, 0.0167714159709801, 0.348332473739967,
								 0.397265998551019, 0.0388523147780617, 0.490733639524639, 0.117553571108702,
								 0.290420863737343, 0.0366925661760856, 0, 0, 0.548138854932161,
								 0.142002447263402, 0, 0.176299657358237, 0.571017417443885),
		conf.high = c(0.94412113651484, 0.234408322505105, 0.102553544652118,
									0.999437540284598, 0.117704331418294, 0.0787051004068431,
									0.578723197043195, 0.963307433823914, 0.578723197043195,
									0.115058399930522, 0.552793090968079, 0.602734001448981,
									0.250832425345653, 0.78992184299333, 0.386308211839583, 0.963307433823914,
									0.709579136262657, 0.409616397225003, 0.097393755914492,
									0.857997552736598, 0.451861145067839, 0.0648707608254246,
									0.428982582556115, 0.823700342641763),
		y.level = c("setosa",
								"versicolor", "virginica", "setosa", "versicolor", "virginica",
								"setosa", "versicolor", "virginica", "setosa", "versicolor",
								"virginica", "setosa", "versicolor", "virginica", "setosa",
								"versicolor", "virginica", "setosa", "versicolor", "virginica",
								"setosa", "versicolor", "virginica")),
	row.names = c(NA, -24L), class = c("tbl_df", "tbl", "data.frame"))


perform_output_tests(model = mod.discr, exp = mod.discr.exp,
										 is_discrete_out = T, tree_length_fun = get_tree_length)

perform_n.obs_test(mod.discr, 'discrete')

perform_predictions_test(mod.discr)

# Continuous model testing --------------------------------------------------

mod.cont <- rpart(Sepal.Width ~ Species + Sepal.Length, data = iris)

# mod.cont %>% tidy_tree(add_interval = T) %>% dput()

mod.cont.exp <- structure(list(
	rule = c(
		"Species = versicolor,virginica",
		"Species = versicolor,virginica & Sepal.Length < 6.35",
		"Species = versicolor,virginica & Sepal.Length < 6.35 & Sepal.Length < 5.55",
		"Species = versicolor,virginica & Sepal.Length < 6.35 & Sepal.Length >= 5.55",
		"Species = versicolor,virginica & Sepal.Length >= 6.35",
		"Species = setosa",
		"Species = setosa & Sepal.Length < 5.05",
		"Species = setosa & Sepal.Length >= 5.05"),
	rule.list = list("Species = versicolor,virginica",
									 c("Species = versicolor,virginica", "Sepal.Length < 6.35"),
									 c("Species = versicolor,virginica", "Sepal.Length < 6.35", "Sepal.Length < 5.55"),
									 c("Species = versicolor,virginica", "Sepal.Length < 6.35", "Sepal.Length >= 5.55"),
									 c("Species = versicolor,virginica", "Sepal.Length >= 6.35"),
									 "Species = setosa",
									 c("Species = setosa", "Sepal.Length < 5.05"),
									 c("Species = setosa", "Sepal.Length >= 5.05")),
	rule.eval = c("Species %in% c(\"versicolor\", \"virginica\")", "Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length < 6.35",
								"Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length < 6.35 & Sepal.Length < 5.55",
								"Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length < 6.35 & Sepal.Length >= 5.55",
								"Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length >= 6.35",
								"Species %in% \"setosa\"", "Species %in% \"setosa\" & Sepal.Length < 5.05",
								"Species %in% \"setosa\" & Sepal.Length >= 5.05"),
	id = c(2, 4, 8, 9, 5, 3, 6, 7),
	n.obs = c(100L, 58L, 12L, 46L, 42L, 50L, 28L, 22L),
	depth = c(1, 2, 3, 3, 2, 1, 2, 2),
	terminal = c(FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE),
	estimate = c(2.872, 2.74137931034483, 2.46666666666667, 2.81304347826087, 3.05238095238095, 3.428, 3.20357142857143, 3.71363636363636),
	conf.low = c(2.81726733000954, 2.67259875797012, 2.35153878102252, 2.74080862244187, 2.98576141584285, 3.33982302037751, 3.11792574978101, 3.61136926311226),
	conf.high = c(2.92673266999046, 2.81015986271953, 2.58179455231081, 2.88527833407986, 3.11900048891906, 3.51617697962249, 3.28921710736185, 3.81590346416047)
), row.names = c(NA, -8L), class = c("tbl_df", "tbl", "data.frame"))

perform_output_tests(model = mod.cont, exp = mod.cont.exp,
										 is_discrete_out = F, tree_length_fun = get_tree_length)

perform_n.obs_test(mod.cont, 'continuous')

perform_predictions_test(mod.cont)
