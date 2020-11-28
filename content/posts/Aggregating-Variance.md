---
title: "Aggregating Variance"
date: 2019-02-03T19:34:55-08:00
toc: true
categories:
  - Statistics
  - Programming
tags:
  - ANOVA
  - R
draft: false
---
The weighted mean has an analogue for variance, closely related to [one-way ANOVA](https://en.wikipedia.org/wiki/One-way_analysis_of_variance). 

<!--more-->

# Background

Suppose you have a dataset released by the United Nations about household incomes around the world, but they aggregated the data before making it public. You only see the mean household income and number of households for each country.

You could compute a weighted mean to recover the grand mean household income as if you had calculated it from the raw, unaggregated sample observations.

I wondered, does the grand variance have a "weighted variance" analogue to the weighted mean? That is, given only summarized data, how could you recover the grand variance of the unaggregated sample?

After some digging I turned up this article, [Composite Standard Deviations](http://www.burtonsys.com/climate/composite_standard_deviations.html), which breaks down precisely this topic! Perhaps unsurprisingly, this entire line of questioning relates closely to analysis of variance (ANOVA).

I'd like to take a stab at explaining my understanding of all this and at deriving the equation at hand, both to cement my understanding and to give MathJax a whirl for my first blog post. Also, see the end of the post for a reference snippet of R code.

# The Punchline

Here's the equation for the grand variance in terms of group summary statistics:

$$
\begin{align}
\sigma^2 = \frac{1}{N-1}\sum_{g=1}^{G} \big[(n_g - 1)\sigma_g^2 + n_g(\mu_g - \mu)^2\big]
\end{align}
$$

Where

* `$G$` is the number of groups,
* `$n_g$` = cardinality (count of observartions) of group `$g \in \{1, 2,\ ...\ , G - 1, G\}$`,
* `$\mu_g$` = mean of group `$g$`,
* `$\sigma_g^2$` = variance of group `$g$`,
* and `$N = \sum_{g=1}^{G} n_g$` is the total sample size.

The equation works regardless of the meaning attached to the groups, or even if the groups were assigned completely at random. However, we need `$n_g \ge 1$` for all groups and the groups should be non-overlapping. In other words, an observation in the original dataset must be aggregated into one group only, a condition shared with the weighted mean.

# How does this relate to one-way ANOVA?

With a few re-arrangements of equation (1) we can map its components directly onto the core mechanics of a one-way ANOVA[^1]:

$$
(N - 1)\sigma^2 = \sum_{g=1}^{G} (n_g - 1)\sigma_g^2 + \sum_{g=1}^{G} n_g(\mu_g - \mu)^2
$$

* `$\sum (n_g - 1)\sigma_g^2$` is ANOVA's "within-group" ("error", "residual", ...) sum of squares term with `$N-G$` degrees of freedom.
* `$\sum n_g(\mu_g - \mu)^2$` is ANOVA's "between-group" ("treatment", "model", ...) sum of squares term with `$G-1$` degrees of freedom.
* Multiply `$\sigma^2$` by the total `$N-1 = (N - G) + (G - 1)$` degrees of freedom to get the "total sum of squares" of ANOVA, the sum total of the squared deviations from the grand mean.

So, you can think of `$\sum (n_g - 1)\sigma_g^2$` as the total variability within groups, `$\sum n_g(\mu_g - \mu)^2$` as the total variability between groups, and the grand variance `$\sigma^2$` combines them.

Note that the equation follows directly from the defintion of variance (see derivation below), so ANOVA's assumptions like normality and identical population variances do not apply. Performing ANOVA requires these assumptions for the [F-test](https://en.wikipedia.org/wiki/F-test) it ultimately boils down to, but aggregating variance does not.

# Derivation

Suppose we have a sample of `$N >= 1$` observations/measurements `$x_1, x_2,\ ...\ , x_N$` of some phenomenon. Let `$x_i$` be the `$i$`<sup>th</sup> observation where `$1 \le i \le N$`.

Then the grand mean `$\mu$` and grand variance `$\sigma^2$` for the sample are given by:

$$
\begin{align}
\mu &= \frac{1}{N} \sum_{i=1}^{N} x_i \\\\
\sigma^2 &= \frac{1}{N-1} \sum_{i=1}^{N} (x_i - \mu)^2
\end{align}
$$

Let `$G$` be the number of groups, and `$1 \le G \le N$`. Assign exactly one group label `$g \in \{1, 2,\ ...\ , G - 1, G\}$` to each observation `$x_i$` such that each group label is used at least once. These group labels could have any meaning attached to them, or be completely arbitrary.

Let `$x_{g,k}$` be the `$k$`<sup>th</sup> point in group `$g$` (order does not matter), and let `$n_g$` be the number of observations `$x_i$` in group `$g$`. We have essentially renamed the observations since there is a bijection between the original observations `$x_i$` and relabelled observations `$x_{g,k}$`. Hence, `$N = \sum_{g=1}^{G} n_g$` and for all `$g$` we have `$n_g \ge 1$`.

The group mean mean `$\mu_g$` and group variance `$\sigma_g^2$` for group `$g$` are given by

$$
\begin{align}
\mu_g &= \frac{1}{n_g} \sum_{k=1}^{n_g} x_{g,k} \\\\
\sigma_g^2 &= \frac{1}{n_g-1} \sum_{k=1}^{n_g} (x_{g,k} - \mu_g)^2
\end{align}
$$

We can express the grand mean `$\mu$` using a weighted mean on the `$\mu_g$` with `$n_g$` as the weights:

$$
\begin{align}
\mu = \frac{1}{N} \sum_{g=1}^{G} \mu_g n_g = \frac{\sum_{g=1}^{G} \mu_g n_g}{\sum_{g=1}^{G} n_g}
\end{align}
$$

Now we can start from definition of the grand variance (3) and through a series of substitutions reach the equation for the grand variance in terms of the group summary statistics (1).

$$
\require{cancel}
\begin{align}
\sigma^2 &= \frac{1}{N-1} \sum_{i=1}^{N} (x_i - \mu)^2 \\\\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} (x_{g,k} - \mu)^2 \\\\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} (x_{g,k} - \mu_g + \mu_g - \mu)^2 \\\\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} \big[(x_{g,k} - \mu_g) + (\mu_g - \mu)\big]^2 \\\\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} \big[(x_{g,k} - \mu_g)^2 + (x_{g,k} - \mu_g)(\mu_g - \mu) + (\mu_g - \mu)^2\big] \\\\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k} - \mu_g)^2 + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k} - \mu_g)(\mu_g - \mu) + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(\mu_g - \mu)^2\bigg] \\\\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k} - \mu_g)^2 + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k}\mu_g - x_{g,k}\mu - \mu_g^2 + \mu_g\mu) + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(\mu_g - \mu)^2\bigg] \\\\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}(n_g-1)\sigma_g^2 + \sum_{g=1}^{G} \big( (n_g \mu_g)\mu_g - (n_g \mu_g)\mu - n_g\mu_g^2 + (n_g)\mu_g\mu \big) + \sum_{g=1}^{G} n_g(\mu_g - \mu)^2\bigg] \\\\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}(n_g-1)\sigma_g^2 + \sum_{g=1}^{G} \big(\cancel{n_g\mu_g^2} - \cancel{n_g\mu_g\mu} - \cancel{n_g\mu_g^2} + \cancel{n_g\mu_g\mu} \big) + \sum_{g=1}^{G} n_g(\mu_g - \mu)^2\bigg] \\\\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}(n_g-1)\sigma_g^2 + \sum_{g=1}^{G} n_g(\mu_g - \mu)^2\bigg] \\\\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\big[(n_g-1)\sigma_g^2 + n_g(\mu_g - \mu)^2\big] \\\\
\end{align}
$$

Note that to get from (13) to (14) uses a re-arrangement (5).

# Code

Finally, here's snippet of R code to demonstrate the equation.

{{< highlight R >}}
library(dplyr)

# Generate 500 points of raw data with random group labels.
N <- 500
dd <- data.frame(
  group = sample(LETTERS, size=N, replace=T),
  observation = rgamma(N, shape=1.1, rate=0.001)
)

# Aggregate the data to mean, variance, and size per group.
agg <- dd %>%
  group_by(group) %>%
  summarize(m = mean(observation), # Group mean
            n = n(),               # Group size
            v = var(observation))  # Group variance

# Grand mean is same as weighted mean of group means.
print(paste("Grand mean from raw observations:", mean(dd$observation)))
print(paste("Grand mean from aggregated data:", sum(agg$m * agg$n) / sum(agg$n)))

# Grand variance can also be recovered from summary stats!
v <- sum((agg$n - 1)*agg$v + agg$n*(agg$m - sum(agg$m*agg$n) / sum(agg$n))^2) / (sum(agg$n) - 1)
print(paste("Grand variance from raw observations:", var(dd$observation)))
print(paste("Grand variance from aggregated data:", v))

{{</highlight>}}


[^1]: The [article](http://www.burtonsys.com/climate/composite_standard_deviations.html) I previously linked to and [this page](https://people.richland.edu/james/lecture/m170/ch13-1wy.html) where helpful to me in understanding the connection.
