% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/list.remove.R
\name{list.remove}
\alias{list.remove}
\title{Remove members from a list by index or name}
\usage{
list.remove(.data, range = integer())
}
\arguments{
\item{.data}{A \code{list} or \code{vector}}

\item{range}{A numeric vector of indices or
a character vector of names to remove from \code{.data}}
}
\description{
Remove members from a list by index or name
}
\examples{
x <- list(p1 = list(type='A',score=list(c1=10,c2=8)),
       p2 = list(type='B',score=list(c1=9,c2=9)),
       p3 = list(type='B',score=list(c1=9,c2=7)))
list.remove(x, 'p1')
list.remove(x, c(1,2))
}

