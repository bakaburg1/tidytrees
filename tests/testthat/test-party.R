
library(partykit)

get_tree_length <- function(model) length(model)

perform_n.obs_test <- function(model, model_type) {
	test_that(paste('the number of observations per node for the', model_type, 'model are correct'), {
		obs <- tidy_tree(model, add_estimates = F)
		exp <- data_party(model, id = obs$id) %>% sapply(nrow)

		expect_equal(obs$n.obs, exp)
	})
}


# General testing ---------------------------------------------------------

perform_method_tests('tidy_tree.party', ctree(Species ~ Sepal.Width + Sepal.Length, data = iris))

test_that('the rules are as in the original tree', {
	mod <- ctree(Species ~ Sepal.Width + Sepal.Length, data = iris)

	exp <- partykit:::.list.rules.party(mod, nodeids(mod)[-1]) %>% setNames(NULL)

	obs <- tidy_tree(mod, rule_as_text = T, add_estimates = F)$rule

	expect_equal(obs, exp)
})

test_that('all nodes are included', {
	mod <- ctree(Species ~ Sepal.Width + Sepal.Length, data = iris)

	obs <- tidy_tree(mod)

	expect_setequal(obs$id, nodeids(mod)[-1])
})

perform_stump_test(ctree)

# Discrete model testing -------------------------------------------------

mod.discr <- ctree(Species ~ Sepal.Width + Sepal.Length, data = iris)

# mod.discr %>% tidy_tree(add_interval = T) %>% dput()

mod.discr.exp <- structure(list(rule = c("Sepal.Length <= 5.4", "Sepal.Length <= 5.4", "Sepal.Length <= 5.4", "Sepal.Length <= 5.4 & Sepal.Width <= 2.7", "Sepal.Length <= 5.4 & Sepal.Width <= 2.7", "Sepal.Length <= 5.4 & Sepal.Width <= 2.7", "Sepal.Length <= 5.4 & Sepal.Width > 2.7", "Sepal.Length <= 5.4 & Sepal.Width > 2.7", "Sepal.Length <= 5.4 & Sepal.Width > 2.7", "Sepal.Length > 5.4", "Sepal.Length > 5.4", "Sepal.Length > 5.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length <= 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length <= 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length <= 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length > 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length > 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length > 6.1", "Sepal.Length > 5.4 & Sepal.Width > 3.4", "Sepal.Length > 5.4 & Sepal.Width > 3.4", "Sepal.Length > 5.4 & Sepal.Width > 3.4"),
																rule.list = list("Sepal.Length <= 5.4", "Sepal.Length <= 5.4", "Sepal.Length <= 5.4", c("Sepal.Length <= 5.4", "Sepal.Width <= 2.7" ), c("Sepal.Length <= 5.4", "Sepal.Width <= 2.7"), c("Sepal.Length <= 5.4", "Sepal.Width <= 2.7"), c("Sepal.Length <= 5.4", "Sepal.Width > 2.7" ), c("Sepal.Length <= 5.4", "Sepal.Width > 2.7"), c("Sepal.Length <= 5.4", "Sepal.Width > 2.7"), "Sepal.Length > 5.4", "Sepal.Length > 5.4", "Sepal.Length > 5.4", c("Sepal.Length > 5.4", "Sepal.Width <= 3.4" ), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4"), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4"), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4", "Sepal.Length <= 6.1"), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4", "Sepal.Length <= 6.1"), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4", "Sepal.Length <= 6.1"), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4", "Sepal.Length > 6.1"), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4", "Sepal.Length > 6.1"), c("Sepal.Length > 5.4", "Sepal.Width <= 3.4", "Sepal.Length > 6.1"), c("Sepal.Length > 5.4", "Sepal.Width > 3.4" ), c("Sepal.Length > 5.4", "Sepal.Width > 3.4"), c("Sepal.Length > 5.4", "Sepal.Width > 3.4")),
																rule.eval = c("Sepal.Length <= 5.4", "Sepal.Length <= 5.4", "Sepal.Length <= 5.4", "Sepal.Length <= 5.4 & Sepal.Width <= 2.7", "Sepal.Length <= 5.4 & Sepal.Width <= 2.7", "Sepal.Length <= 5.4 & Sepal.Width <= 2.7", "Sepal.Length <= 5.4 & Sepal.Width > 2.7", "Sepal.Length <= 5.4 & Sepal.Width > 2.7", "Sepal.Length <= 5.4 & Sepal.Width > 2.7", "Sepal.Length > 5.4", "Sepal.Length > 5.4", "Sepal.Length > 5.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length <= 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length <= 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length <= 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length > 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length > 6.1", "Sepal.Length > 5.4 & Sepal.Width <= 3.4 & Sepal.Length > 6.1", "Sepal.Length > 5.4 & Sepal.Width > 3.4", "Sepal.Length > 5.4 & Sepal.Width > 3.4", "Sepal.Length > 5.4 & Sepal.Width > 3.4"),
																id = c(2L, 2L, 2L, 3L, 3L, 3L, 4L, 4L, 4L, 5L, 5L, 5L, 6L, 6L, 6L, 7L, 7L, 7L, 8L, 8L, 8L, 9L, 9L, 9L),
																n.obs = c(52L, 52L, 52L, 7L, 7L, 7L, 45L, 45L, 45L, 98L, 98L, 98L, 90L, 90L, 90L, 38L, 38L, 38L, 52L, 52L, 52L, 8L, 8L, 8L),
																terminal = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
																depth = c(1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 2, 2, 2),
																estimate = c(0.865384615384615, 0.115384615384615, 0.0192307692307692, 0.142857142857143,
																						 0.714285714285714, 0.142857142857143, 0.977777777777778, 0.0222222222222222,
																						 0, 0.0510204081632653, 0.448979591836735, 0.5, 0, 0.488888888888889,
																						 0.511111111111111, 0, 0.736842105263158, 0.263157894736842, 0,
																						 0.307692307692308, 0.692307692307692, 0.625, 0, 0.375),
																conf.low = c(0.742121414960492, 0.0435412039886871, 0.000486762415492083,
																						 0.00361029686190059, 0.290420863737343, 0.00361029686190059,
																						 0.882295668581706, 0.000562459715402258, 0, 0.0167714159709801,
																						 0.348332473739967, 0.397265998551019, 0, 0.381987486252586, 0.403458132715541,
																						 0, 0.568991756297761, 0.134033723024974, 0, 0.187173369199779,
																						 0.548976017783368, 0.244863216366552, 0, 0.0852334141372536),
																conf.high = c(0.94412113651484, 0.234408322505105, 0.102553544652118, 0.578723197043195,
																							0.963307433823914, 0.578723197043195, 0.999437540284598, 0.117704331418294,
																							0.0787051004068431, 0.115058399930522, 0.552793090968079, 0.602734001448981,
																							0.0401589196157747, 0.596541867284459, 0.618012513747414, 0.0925127614158783,
																							0.865966276975026, 0.431008243702239, 0.0684822087033196, 0.451023982216632,
																							0.812826630800221, 0.914766585862746, 0.369416647552819, 0.755136783633448),
																y.level = c("setosa", "versicolor", "virginica", "setosa", "versicolor",
																						"virginica", "setosa", "versicolor", "virginica", "setosa", "versicolor",
																						"virginica", "setosa", "versicolor", "virginica", "setosa", "versicolor",
																						"virginica", "setosa", "versicolor", "virginica", "setosa", "versicolor",
																						"virginica")),
													 row.names = c(NA, -24L),  class = c("tbl_df", "tbl", "data.frame"))

perform_output_tests(model = mod.discr, exp = mod.discr.exp,
										 is_discrete_out = T, tree_length_fun = get_tree_length)

perform_n.obs_test(mod.discr, 'discrete')

perform_predictions_test(mod.discr)

# Continuous model testing --------------------------------------------------

mod.cont <- ctree(Sepal.Width ~ Species + Sepal.Length, data = iris)

# mod.cont %>% tidy_tree(add_interval = T) %>% dput()

mod.cont.exp <- structure(list(rule = c("Species in setosa", "Species in setosa & Sepal.Length <= 5", "Species in setosa & Sepal.Length <= 5 & Sepal.Length <= 4.9", "Species in setosa & Sepal.Length <= 5 & Sepal.Length > 4.9", "Species in setosa & Sepal.Length > 5", "Species in setosa & Sepal.Length > 5 & Sepal.Length <= 5.3", "Species in setosa & Sepal.Length > 5 & Sepal.Length > 5.3", "Species in versicolor, virginica", "Species in versicolor, virginica & Sepal.Length <= 6.3", "Species in versicolor, virginica & Sepal.Length <= 6.3 & Sepal.Length <= 5.5", "Species in versicolor, virginica & Sepal.Length <= 6.3 & Sepal.Length > 5.5", "Species in versicolor, virginica & Sepal.Length > 6.3"),
															 rule.list = list("Species in setosa", c("Species in setosa", "Sepal.Length <= 5"), c("Species in setosa", "Sepal.Length <= 5", "Sepal.Length <= 4.9"), c("Species in setosa", "Sepal.Length <= 5", "Sepal.Length > 4.9"), c("Species in setosa", "Sepal.Length > 5"), c("Species in setosa", "Sepal.Length > 5", "Sepal.Length <= 5.3"), c("Species in setosa", "Sepal.Length > 5", "Sepal.Length > 5.3"), "Species in versicolor, virginica", c("Species in versicolor, virginica", "Sepal.Length <= 6.3"), c("Species in versicolor, virginica", "Sepal.Length <= 6.3", "Sepal.Length <= 5.5"), c("Species in versicolor, virginica", "Sepal.Length <= 6.3", "Sepal.Length > 5.5"), c("Species in versicolor, virginica", "Sepal.Length > 6.3")),
															 rule.eval = c("Species %in% c(\"setosa\")", "Species %in% c(\"setosa\") & Sepal.Length <= 5",
															 							"Species %in% c(\"setosa\") & Sepal.Length <= 5 & Sepal.Length <= 4.9",
															 							"Species %in% c(\"setosa\") & Sepal.Length <= 5 & Sepal.Length > 4.9",
															 							"Species %in% c(\"setosa\") & Sepal.Length > 5", "Species %in% c(\"setosa\") & Sepal.Length > 5 & Sepal.Length <= 5.3",
															 							"Species %in% c(\"setosa\") & Sepal.Length > 5 & Sepal.Length > 5.3",
															 							"Species %in% c(\"versicolor\", \"virginica\")", "Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length <= 6.3",
															 							"Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length <= 6.3 & Sepal.Length <= 5.5",
															 							"Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length <= 6.3 & Sepal.Length > 5.5",
															 							"Species %in% c(\"versicolor\", \"virginica\") & Sepal.Length > 6.3"
															 ),
															 id = 2:13, n.obs = c(50L, 28L, 20L, 8L, 22L, 12L, 10L, 100L, 58L, 12L, 46L, 42L),
															 terminal = c(FALSE, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, FALSE,
															 						 TRUE, TRUE, TRUE),
															 depth = c(1, 2, 3, 3, 2, 3, 3, 1, 2, 3, 3, 2),
															 estimate = c(3.428, 3.20357142857143, 3.14, 3.3625, 3.71363636363636, 3.625, 3.82, 2.872, 2.74137931034483, 2.46666666666667, 2.81304347826087, 3.05238095238095),
															 conf.low = c(3.33982302037751, 3.11792574978101, 3.03638177958466, 3.25069186006287, 3.61136926311226, 3.51573319205604, 3.64696431709426, 2.81726733000954, 2.67259875797012, 2.35153878102252, 2.74080862244187, 2.98576141584285),
															 conf.high = c(3.51617697962249, 3.28921710736185, 3.24361822041534, 3.47430813993713, 3.81590346416047, 3.73426680794396, 3.99303568290574, 2.92673266999046, 2.81015986271953, 2.58179455231081, 2.88527833407986, 3.11900048891906)),
													row.names = c(NA, -12L),
													class = c("tbl_df", "tbl", "data.frame"))

perform_output_tests(model = mod.cont, exp = mod.cont.exp,
										 is_discrete_out = F, tree_length_fun = get_tree_length)

perform_n.obs_test(mod.cont, 'continuous')

perform_predictions_test(mod.cont)
