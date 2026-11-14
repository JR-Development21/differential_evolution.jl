library(dplyr)

setwd("C:/Users/ritch/Documents/DOE Papers/differential_evolution.jl/")

file_to_id <- function(file_path){
  folder <- basename(dirname(file_path))
  if (grepl("pure", folder)){
    return("L-SHADE-pure")
  }
  if (grepl("full", folder)){
    return("PSO-full")
  }
  stop("Unknown algorithm in file path")
}

load_efficiency_data <- function(file_path){
  dat <- read.csv(file_path)
  colnames(dat)[colnames(dat) == "k"] <- "K"
  colnames(dat)[colnames(dat) == "Sv"] <- "Agents"
  dat <- dat
  dat$Algorithm <- file_to_id(file_path)
  dat
}

summarize_efficiency <- function(file_list){
  dat_list <- lapply(file_list, load_efficiency_data)
  dat <- bind_rows(dat_list)
  dat <- dat %>%
    group_by(N, K) %>%
    mutate(Efficiency = fgbest / min(fgbest)) %>%
    ungroup() %>%
    filter(Agents == 500) %>%
    group_by(N, K, Algorithm) %>%
    summarize(
      `Average Efficiency` = mean(Efficiency),
      `SD Efficiency` = sd(Efficiency),
      .groups = "drop"
    )
  dat
}

latex_bold_best <- function(x, best_x){
  format_x <- sprintf("%.3f", x)
  ifelse(abs(x - best_x) < 1e-10, paste0("\\textbf{", format_x, "}"), format_x)
}

make_latex_table <- function(summary_dat, criterion_name){
  group_keys <- unique(summary_dat[, c("K", "N")])
  group_keys <- group_keys[order(group_keys$K, group_keys$N), ]
  algorithm_names <- unique(summary_dat$Algorithm)
  algorithm_names <- algorithm_names[order(algorithm_names)]

  output_lines <- c(
    "\\begin{table}[t]",
    "  \\centering",
    paste0("  \\caption{Average and standard deviation of comparative efficiency for the 500-agent case in the ", criterion_name, ".}"),
    "  \\begin{tabular}{lcc}",
    "    \\toprule",
    paste0("    $(K,N)$ & Augmented L-SHADE & PSO ", "\\\\"),
    "    \\midrule"
  )

  for (i in seq_len(nrow(group_keys))){
    N_val <- group_keys$N[i]
    K_val <- group_keys$K[i]

    values_by_algorithm <- lapply(algorithm_names, function(alg){
      row_idx <- which(summary_dat$N == N_val & summary_dat$K == K_val & summary_dat$Algorithm == alg)
      if (length(row_idx) == 0) {
        stop(paste("No summary row found for:", criterion_name, N_val, K_val, alg))
      }
      row <- summary_dat[row_idx, ]
      list(
        mean = row$`Average Efficiency`,
        sd = row$`SD Efficiency`
      )
    })
    names(values_by_algorithm) <- algorithm_names

    best_mean <- max(vapply(values_by_algorithm, function(x) x$mean, numeric(1)))
    best_sd <- min(vapply(values_by_algorithm, function(x) x$sd, numeric(1)))

    cell_1 <- values_by_algorithm[[algorithm_names[1]]]
    cell_2 <- values_by_algorithm[[algorithm_names[2]]]

    cell_1_mean <- latex_bold_best(cell_1$mean, best_mean)
    cell_1_sd <- latex_bold_best(cell_1$sd, best_sd)
    cell_2_mean <- latex_bold_best(cell_2$mean, best_mean)
    cell_2_sd <- latex_bold_best(cell_2$sd, best_sd)

    cell_1_text <- paste0(cell_1_mean, " $\\pm$ ", cell_1_sd)
    cell_2_text <- paste0(cell_2_mean, " $\\pm$ ", cell_2_sd)

    output_lines <- c(
      output_lines,
      paste0("    (", K_val, ",", N_val, ") & ", cell_1_text, " & ", cell_2_text, " ", "\\\\")
    )
  }

  output_lines <- c(
    output_lines,
    "    \\bottomrule",
    "  \\end{tabular}",
    "\\end{table}"
  )

  output_lines
}

criterion_file_lists <- list(
  "D-Criterion" = c(
    "L-SHADE-pure/D_sim.csv",
    "../PSO_OptDoE_development/PSO-full/D_sim.csv"
  ),
  "I-Criterion" = c(
    "L-SHADE-pure/I_sim.csv",
    "../PSO_OptDoE_development/PSO-full/I_sim.csv"
  ),
  "A-Criterion" = c(
    "L-SHADE-pure/A_sim.csv",
    "../PSO_OptDoE_development/PSO-full/A_sim.csv"
  ),
  "G-Criterion" = c(
    "L-SHADE-pure/G_sim.csv",
    "../PSO_OptDoE_development/PSO-full/G_sim.csv"
  )
)

tex_lines <- c(
  "\\documentclass{article}",
  "\\usepackage{booktabs}",
  "\\usepackage{array}",
  "\\begin{document}"
)

for (criterion_name in names(criterion_file_lists)){
  summary_dat <- summarize_efficiency(criterion_file_lists[[criterion_name]])
  tex_lines <- c(tex_lines, make_latex_table(summary_dat, criterion_name), "")
}

tex_lines <- c(tex_lines, "\\end{document}")
writeLines(tex_lines, con = "efficiency_tables.tex")

cat("LaTeX table script complete: efficiency_tables.tex\n")