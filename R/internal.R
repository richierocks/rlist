.expr <- NULL

map <- function(f, dots, more = NULL, use.names = TRUE) {
  res <- .mapply(f, dots, more)
  if (use.names && length(dots)) {
    if (!is.null(names1 <- names(dot1 <- dots[[1L]])))
      names(res) <- names1 else if (is.character(dot1))
      names(res) <- dot1
  }
  res
}

reduce <- function(f, x, init, ...) {
  y <- init
  for (xi in x) y <- f(y, xi, ...)
  y
}

list.map.fun <- function(.data, ., .i, .name) {
  eval(.expr, .evalwith(.data), environment())
}

list.map.internal <- function(.data, expr, envir, fun = list.map.fun, args = NULL) {
  if (is.empty(.data))
    return(list())
  l <- lambda(expr)
  xnames <- getnames(.data, character(1L))
  environment(fun) <- args_env(.expr = l$expr, .args = args, .evalwith = .evalwith,
    parent = envir)
  formals(fun) <- setnames(formals(fun), c(".data", l$symbols))
  map(fun, list(.data, .data, seq_along(.data), xnames))
}

list.is.fun <- function(.data, ., .i, .name) {
  x <- eval(.expr, .evalwith(.data), environment())
  if (is.logical(x) && length(x) == 1L)
    x else NA
}

list.is.internal <- function(.data, cond, envir) {
  as.logical(list.map.internal(.data, cond, envir, list.is.fun))
}

list.findi.fun <- function(.data, ., .i, .name) {
  .args$i <- .args$i + 1L
  x <- eval(.expr, .evalwith(.data), environment())
  if (is.logical(x) && length(x) == 1L && !is.na(x)) {
    if (x) {
      .args$n <- .args$n + 1L
      .args$indices[[.args$n]] <- .args$i
      if (.args$n == .args$N)
        stop("finished", call. = FALSE)
    }
  } else if (.args$na.stop)
    stop("stopped", call. = FALSE)
}

list.findi.internal <- function(.data, cond, envir, n, na.stop = FALSE) {
  n <- min(n, length(.data))
  args <- args_env(i = 0L, n = 0L, N = n, na.stop = na.stop, indices = integer(n))
  result <- try(list.map.internal(.data, cond, envir, list.findi.fun, args), silent = TRUE)
  if (is.error(result)) {
    switch(attr(result, "condition")$message, finished = NULL, stopped = warning("Encountered value that is not TRUE or FALSE"),
      stop(message, call. = FALSE))
  }
  args$indices[0L:args$n]
}

list.first.fun <- function(.data, ., .i, .name) {
  x <- eval(.expr, .evalwith(.data), environment())
  if (is.logical(x) && length(x) == 1L && !is.na(x)) {
    if (x) {
      .args$res <- list(state = TRUE, value = .data)
      stop(call. = FALSE)
    }
  } else if (!.args$na.rm) {
    .args$res <- list(state = NA, value = .data)
  }
}

list.first.internal <- function(.data, cond, envir, na.rm) {
  args <- args_env(res = list(state = FALSE), na.rm = na.rm)
  try(list.map.internal(.data, cond, envir, list.first.fun, args), silent = TRUE)
  args$res
}

list.while.fun <- function(.data, ., .i, .name) {
  x <- eval(.expr, .evalwith(.data), environment())
  if (is.logical(x) && length(x) == 1L && !is.na(x) && x)
    .args$i <- .args$i + 1L else stop(call. = FALSE)
}

list.order.internal <- function(.data, args, envir, na.last = TRUE) {
  if (is.empty(.data))
    return(integer())
  if (is.empty(args))
    return(order(.data))
  cols <- lapply(args, function(arg) {
    if (is.null(arg))
      stop("NULL condition", call. = FALSE)
    desc <- class(arg) == "("
    if (desc)
      arg <- arg[[2L]]
    col <- list.map.internal(.data, arg, envir)
    if (length(unique.default(vapply(col, "class", character(1L)))) > 1L) {
      warning("Inconsistent classes of values in column [", deparse(arg), "]. The column will be coerced to the same class.",
        call. = FALSE)
    }
    lens <- vapply(col, "length", integer(1L))
    if (any(lens != 1L)) {
      warning("Non-single value in column [", deparse(arg), "]. Use NA instead to order.",
        call. = FALSE)
      col[lens != 1L] <- NA
    }
    col <- unlist(col, recursive = FALSE, use.names = FALSE)
    if (desc)
      col <- -xtfrm(col)
    col
  })
  do.call("order", c(cols, na.last = na.last))
}

list.search.fun <- function(.data, .expr, .args, .n = .args$n, . = .data, .i = .args$i,
  .name = NULL) {
  .args$i <- .args$i + 1L
  q <- eval(.expr, NULL, environment())
  vq <- !is.na(q)
  if (is.logical(q) && length(q) == 1L && !is.na(q)) {
    if (q) {
      .args$n <- .args$n + 1L
      .args$indices[[.args$n]] <- .args$i
      .args$result[[.args$n]] <- .data
      if (.args$n == .args$N)
        stop("finished", call. = FALSE)
    }
  } else if (length(q) >= 1L && any(vq)) {
    .args$n <- .args$n + 1L
    .args$indices[[.args$n]] <- .args$i
    .args$result[[.args$n]] <- q[vq]
    if (.args$n == .args$N)
      stop("finished", call. = FALSE)
  }
}

list.group.internal <- function(.data, keys, envir, proc = NULL, compare = "identical",
  sorted = TRUE) {
  if (is.empty(keys))
    return(.data)
  values <- list.map.internal(.data, keys[[1L]], envir)
  proc <- if (!missing(proc) && !is.null(proc) && !is.function(proc))
    match.fun(proc) else NULL
  uvalues <- if (is.function(proc))
    proc(values) else values
  uniques <- unique.default(uvalues)
  names(uniques) <- uniques
  if (sorted && all(vapply(uniques, length, integer(1L)) == 1L))
    uniques <- sort(c(uniques, recursive = TRUE))
  lapply(uniques, function(key, ...) {
    selector <- vapply(values, compare, logical(1L), key, USE.NAMES = FALSE)
    list.group.internal(.data[selector], keys[-1L], ...)
  }, envir, proc, compare, sorted)
}
