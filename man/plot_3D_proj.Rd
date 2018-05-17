% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{plot_3D_proj}
\alias{plot_3D_proj}
\title{Plots the 3D representation of the projection function}
\usage{
plot_3D_proj(X, bpwpm_params, n, f_of_0 = TRUE)
}
\arguments{
\item{X}{Input Matrix of 2D (2 columns).}

\item{bpwpm_params}{A list of bpwpm parameters created by the function
\code{\link{posterior_params}}}

\item{n}{How thin is the grid to be made}

\item{f_of_0}{If the constant function 0 is to be ploted}
}
\value{
a 3d WireFrame Plot
}
\description{
Given the set of parmeters and the input data in 2D, this function calculates
and plots the data on a 3D linear space defined by the input matrix X.
}