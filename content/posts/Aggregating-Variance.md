---
title: "Aggregating Variance"
date: 2019-02-03T19:34:55-08:00
toc: true
categories:
  - Statistics
tags:
  - ANOVA
  - R
draft: false
---
One-way ANOVA is the key to a "weighted variance" analogue to the weighted mean.

<!--more-->

# Background

Suppose you have a dataset released by the United Nations about household incomes around the world. However, the UN aggregated the data before making it public: you only see the mean household income and number of households for each country.

From this summarized data you could recover the overall (grand) mean household income across the world. Just compute a weighted mean over the group means, weighting each group mean by the number of houses it represents.

I wanted to know: is there an analogue to the weighted mean for the grand variance? That is, given only summarized data, how would one recover the grand variance?

After some digging I turned up [this article](http://www.burtonsys.com/climate/composite_standard_deviations.html) which touches on precisely this topic! Perhaps unsurprisingly, this entire line of questioning is deeply related to analysis of variance (ANOVA). Basically, you would need one additional summary statistic per group, the variance in the household income, to compute the grand variance.

Unfortunately the article is an edited email correspondence in plain text so the notation was a little hard for me to follow. Despite the non-standard notation, the article helped me wrap my head around this so I really appreciate the author sharing the correspondence.

I'd like to take a stab deriving the formula in a more direct way, both to cement my understanding and to give MathJax a whirl for my first blog post. Finally, see the end for a quick R snippet demonstrating the formula.

# Punchline

Here's the important formula, see the derivation below if interested.
```$$
\begin{align}
\sigma^2 = \frac{1}{N-1}\sum_{g=1}^{G} \big[(n_g - 1)\sigma_g^2 + n_g(\mu_g - \mu)^2\big]
\end{align}
$$```
Where

* `$G$` is the number of groups,
* `$n_g$`, `$\mu_g$`, and `$\sigma_g^2$` are the size, mean, and variance of group `$g \in \{1, 2,\ ...\ , G - 1, G\}$`,
* and `$N = \sum_{g=1}^{G} n_g$` is the total sample size.

While I won't explain one-way ANOVA[^1], you can see that the `$\sum (n_g - 1)\sigma_g^2$` expression is exactly equal to ANOVA's "within-group sum of squares" term (aka error sum of squares), and the expression `$\sum n_g(\mu_g - \mu)^2$` is exactly equal to the "between-group sum of squares" term (aka treatment sum of squares) in ANOVA. Additionally, if you didn't divide the entire expression by `$N-1$` you would have the "total sum of squares" of ANOVA.

# Derivation

Suppose we have `$N >= 1$` observations `$x_1, x_2,\ ...\ , x_N$` of some phenomenon. Let `$x_i$` be the `$i$`<sup>th</sup> observation.

Then the grand mean `$\mu$` and grand variance `$\sigma^2$` are given by:
```$$
\begin{align}
\mu &= \frac{1}{N} \sum_{i=1}^{N} x_i \\
\sigma^2 &= \frac{1}{N-1} \sum_{i=1}^{N} (x_i - \mu)^2
\end{align}
$$```
Let `$G \in \{1, 2,\ ...\ , N-1, N\}$` be the number of groups. Assign exactly one group label `$g \in \{1, 2,\ ...\ , G - 1, G\}$` to each observation `$x_i$` such that each group label is used at least once. These group labels could have any meaning attached to them, or be completely arbitrary.

Let `$x_{g,k}$` be the `$k$`<sup>th</sup> point in group `$g$` (order does not matter), and let `$n_g$` be the number of observations `$x_i$` in group `$g$`. We have in effect renamed the observations since there is a bijection between the original observations `$x_i$` and relabelled observations `$x_{g,k}$`. Hence, `$N = \sum_{g=1}^{G} n_g$` and for all `$g$` we have `$n_g > 1$`.

The group mean mean `$\mu_g$` and group variance `$\sigma_g^2$` for group `$g$` are given by
```$$
\begin{align}
\mu_g &= \frac{1}{n_g} \sum_{k=1}^{n_g} x_{g,k} \\
\sigma_g^2 &= \frac{1}{n_g-1} \sum_{k=1}^{n_g} (x_{g,k} - \mu_g)^2
\end{align}
$$```
We can express the grand mean `$\mu$` using a weighted mean on the `$\mu_g$` with `$n_g$` as the weights:
```$$
\begin{align}
\mu = \frac{1}{N} \sum_{g=1}^{G} \mu_g n_g = \frac{\sum_{g=1}^{G} \mu_g n_g}{\sum_{g=1}^{G} n_g}
\end{align}
$$```
Now we can start from definition of the grand variance (3) and through a series of substitutions reach the equation for the grand variance in terms of the group summary statistics (1).
```$$
\require{cancel}
\begin{align}
\sigma^2 &= \frac{1}{N-1} \sum_{i=1}^{N} (x_i - \mu)^2 \\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} (x_{g,k} - \mu)^2 \\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} (x_{g,k} - \mu_g + \mu_g - \mu)^2 \\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} \big[(x_{g,k} - \mu_g) + (\mu_g - \mu)\big]^2 \\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\sum_{k=1}^{n_g} \big[(x_{g,k} - \mu_g)^2 + (x_{g,k} - \mu_g)(\mu_g - \mu) + (\mu_g - \mu)^2\big] \\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k} - \mu_g)^2 + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k} - \mu_g)(\mu_g - \mu) + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(\mu_g - \mu)^2\bigg] \\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k} - \mu_g)^2 + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(x_{g,k}\mu_g - x_{g,k}\mu - \mu_g^2 + \mu_g\mu) + \sum_{g=1}^{G}\sum_{k=1}^{n_g}(\mu_g - \mu)^2\bigg] \\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}(n_g-1)\sigma_g^2 + \sum_{g=1}^{G} \big( (n_g \mu_g)\mu_g - (n_g \mu_g)\mu - n_g\mu_g^2 + (n_g)\mu_g\mu \big) + \sum_{g=1}^{G} n_g(\mu_g - \mu)^2\bigg] \\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}(n_g-1)\sigma_g^2 + \sum_{g=1}^{G} \big(\cancel{n_g\mu_g^2} - \cancel{n_g\mu_g\mu} - \cancel{n_g\mu_g^2} + \cancel{n_g\mu_g\mu} \big) + \sum_{g=1}^{G} n_g(\mu_g - \mu)^2\bigg] \\
         &= \frac{1}{N-1} \bigg[\sum_{g=1}^{G}(n_g-1)\sigma_g^2 + \sum_{g=1}^{G} n_g(\mu_g - \mu)^2\bigg] \\
         &= \frac{1}{N-1} \sum_{g=1}^{G}\big[(n_g-1)\sigma_g^2 + n_g(\mu_g - \mu)^2\big] \\
\end{align}
$$```
Note that to get from (13) to (14) uses a re-arrangement (5).

# Code

Finally, here's snippet of R code to demonstrate the formula.

{{< highlight R >}}
library(dplyr)

# Generate 500 points of raw data with random group labels.
N <- 500
dd <- data.frame(
  group = sample(LETTERS, size=N, replace=T),
  observation = rnorm(N, mean=100, sd=10)
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



[^1]: The [article](http://www.burtonsys.com/climate/composite_standard_deviations.html) I previously linked to and [this page](https://people.richland.edu/james/lecture/m170/ch13-1wy.html) where helpful to me in making these connections.
