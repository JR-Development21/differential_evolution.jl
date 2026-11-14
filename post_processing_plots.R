library(dplyr)
library(ggplot2)
library(ggpubr)
library(patchwork)

setwd("C:/Users/ritch/Documents/DOE Papers/differential_evolution.jl/")

file_path <- "L-SHADE-pure/G_sim.csv"

lshade_iter_to_fe_exact <- function(iterations,
                                    max_fe,
                                    start_agents,
                                    min_agents = 4) {
  
  fe_used <- start_agents
  
  if (iterations == 0)
    return(fe_used)
  
  for (i in seq_len(iterations)) {
    
    np <- round(
      start_agents -
        (start_agents - min_agents) *
        fe_used / max_fe
    )
    
    fe_used <- fe_used + np
    
    if (fe_used >= max_fe)
      return(max_fe)
  }
  
  fe_used
}

#make load dataset that gets the function evaluations if they don't already, then saves the new dataset

load_dataset <- function(file_path){
  dat <- read.csv(file_path)
  if("fcn_evals" %in% colnames(dat)){
    return(dat)
  }
  dat$fcn_evals <- sapply(1:nrow(dat), function(x) lshade_iter_to_fe_exact(dat$niter[x], 1000 * dat$Sv[x], dat$Sv[x]))
  write.csv(dat, file_path)
  return(dat)
}

load_pso <- function(file_path){
  dat <- read.csv(file_path)
  dat$fcn_evals <- dat$Sv * dat$niter
  write.csv(dat, file_path)
}

# pso_file_list <- c(
#   "C:/Users/ritch/Documents/DOE Papers/PSO_OptDoE_development/PSO-full/G_sim.csv",
#   "C:/Users/ritch/Documents/DOE Papers/PSO_OptDoE_development/PSO-full/A_sim.csv",
#   "C:/Users/ritch/Documents/DOE Papers/PSO_OptDoE_development/PSO-full/I_sim.csv",
#   "C:/Users/ritch/Documents/DOE Papers/PSO_OptDoE_development/PSO-full/D_sim.csv"
# )
# 
# for(file in pso_file_list){
#   load_pso(file)
# }

file_to_id <- function(file_path){
  if (grepl("pure", file_path)){
    return("Augmented L-SHADE")
  }
  if (grepl("normal", file_path)){
    return("Adjusted")
  }
  if (grepl("arch", file_path)){
    return("Archive")
  }
  if (grepl("exact", file_path)){
    return("Traditional")
  }
  if (grepl("full", file_path)){
    return("PSO")
  }
  if (grepl("early", file_path)){
    return("Early-Stopping PSO")
  }
  
}


make_raw_plots <- function(file_list, title){
  d_crit_bool <- grepl("D-Criterion", title)
  dat_list <- lapply(file_list, function(x) load_dataset(x))
  id_vec <- sapply(file_list, function(x) file_to_id(x))
  names(dat_list) <- id_vec
  dat <- bind_rows(dat_list, .id = "Algorithm")
  colnames(dat)[colnames(dat) == "k"] <- "K"
  colnames(dat)[colnames(dat) == "Sv"] <- "Agents"
  if(d_crit_bool){
    dat <- dat |> 
      group_by(N,K) |> 
      mutate(fgbest = fgbest / min(fgbest))
  } else{
    dat <- dat |> 
      group_by(N,K) |> 
      mutate(fgbest = fgbest / min(fgbest))
  }
  
  box_plot <- ggplot(data = dat, aes(x = as.factor(N), y = fgbest, color = `Algorithm`)) +
    geom_boxplot() +
    facet_grid(cols = vars(K),
               rows = vars(`Agents`),
               scales = "free",
               labeller = "label_both") +
    ylab("Comparitive Efficiency") +
    xlab("N") +
    theme(legend.direction = "horizontal",
          text = element_text(family = "serif", size = 18),
          legend.position = "none")
  return(box_plot)
}

make_average_plots <- function(criterion_file_lists){
  dat_list <- lapply(names(criterion_file_lists), function(criterion){
    file_list <- criterion_file_lists[[criterion]]
    criterion_dat_list <- lapply(file_list, load_dataset)
    names(criterion_dat_list) <- sapply(file_list, file_to_id)
    criterion_dat <- bind_rows(criterion_dat_list, .id = "Algorithm")
    criterion_dat$Criterion <- criterion
    criterion_dat
  })
  dat <- bind_rows(dat_list)
  dat$Criterion <- factor(dat$Criterion, levels = names(criterion_file_lists))
  colnames(dat)[colnames(dat) == "k"] <- "K"
  colnames(dat)[colnames(dat) == "Sv"] <- "Agents"

  dat <- dat |> 
    group_by(Criterion, N, K) |> 
    mutate(fgbest = fgbest / min(fgbest)) |>
    ungroup()

  
  dat <- dat |> 
    group_by(Criterion, Agents, K, Algorithm) |> 
    summarize(`Average Efficiency` = mean(fgbest), .groups = "drop")
  
  line_plot <- ggplot(data = dat, aes(x = K, y = `Average Efficiency`, color = `Algorithm`, shape = `Algorithm`)) +
    geom_line() +
    geom_point() +
    facet_grid(rows = vars(`Agents`),
               cols = vars(Criterion),
               labeller = "label_both") +
    ylab("Average Comparitive Efficiency") +
    xlab("K") +
    theme(text = element_text(family = "serif", size = 18),
          legend.position = "bottom")
  return(line_plot)
}

make_95_plots <- function(criterion_file_lists){
  dat_list <- lapply(names(criterion_file_lists), function(criterion){
    file_list <- criterion_file_lists[[criterion]]
    criterion_dat_list <- lapply(file_list, load_dataset)
    names(criterion_dat_list) <- sapply(file_list, file_to_id)
    criterion_dat <- bind_rows(criterion_dat_list, .id = "Algorithm")
    criterion_dat$Criterion <- criterion
    criterion_dat
  })
  dat <- bind_rows(dat_list)
  dat$Criterion <- factor(dat$Criterion, levels = names(criterion_file_lists))
  colnames(dat)[colnames(dat) == "k"] <- "K"
  colnames(dat)[colnames(dat) == "Sv"] <- "Agents"

  dat <- dat |> 
    group_by(Criterion, N, K) |> 
    mutate(fgbest = fgbest / min(fgbest)) |>
    ungroup()

  
  dat <- dat |> 
    group_by(Criterion, Agents, K, Algorithm) |> 
    summarize(`Percent of High Efficiency Designs` = mean(fgbest >= .95), .groups = "drop")
  
  line_plot <- ggplot(data = dat, aes(x = K, y = `Percent of High Efficiency Designs`, color = `Algorithm`, shape = `Algorithm`)) +
    geom_line() +
    geom_point() +
    facet_grid(rows = vars(`Agents`),
               cols = vars(Criterion),
               labeller = "label_both") +
    xlab("K") +
    theme(text = element_text(family = "serif", size = 18),
          legend.position = "bottom")
  return(line_plot)
}

# file_list <- c("L-SHADE-pure/I_sim.csv",
#                "L-SHADE-normal/I_sim.csv",
#                "L-SHADE-exact/I_sim.csv",
#                "L-SHADE-arch/I_sim.csv")
# 
# (box_out <- make_raw_plots(file_list, "I-Criterion L-SHADE Comparison"))
# ggsave("Plots/i_crit_lshade.pdf", height = 6, width = 8, units = "in")
# 
# 
# file_list <- c("L-SHADE-pure/A_sim.csv",
#                "L-SHADE-normal/A_sim.csv",
#                "L-SHADE-exact/A_sim.csv",
#                "L-SHADE-arch/A_sim.csv")
# 
# (box_out <- make_raw_plots(file_list, "A-Criterion L-SHADE Comparison"))
# ggsave("Plots/a_crit_lshade.pdf", height = 6, width = 8, units = "in")
# 
# file_list <- c("L-SHADE-pure/G_sim.csv",
#                "L-SHADE-normal/G_sim.csv",
#                "L-SHADE-exact/G_sim.csv",
#                "L-SHADE-arch/G_sim.csv")
# 
# (box_out <- make_raw_plots(file_list, "G-Criterion L-SHADE Comparison"))
# ggsave("Plots/g_crit_lshade.pdf", height = 6, width = 8, units = "in")
# 
# file_list <- c("L-SHADE-pure/D_sim.csv",
#                "L-SHADE-normal/D_sim.csv",
#                "L-SHADE-exact/D_sim.csv",
#                "L-SHADE-arch/D_sim.csv")
# 
# (box_out <- make_raw_plots(file_list, "D-Criterion L-SHADE Comparison"))
# ggsave("Plots/d_crit_lshade.pdf", height = 6, width = 8, units = "in")


########## include pso

file_list <- c("L-SHADE-pure/I_sim.csv",
               "../PSO_OptDoE_development/PSO-full/I_sim.csv"
               )

(box_out <- make_raw_plots(file_list, "I-Criterion L-SHADE Comparison"))
ggsave("Plots/i_crit_comp.pdf", height = 6, width = 8, units = "in")


file_list <- c("L-SHADE-pure/A_sim.csv",
               "../PSO_OptDoE_development/PSO-full/A_sim.csv"
               )

(box_out <- make_raw_plots(file_list, "A-Criterion L-SHADE Comparison"))
ggsave("Plots/a_crit_comp.pdf", height = 6, width = 8, units = "in")

file_list <- c("L-SHADE-pure/G_sim.csv",
               "../PSO_OptDoE_development/PSO-full/G_sim.csv"
               )

(box_out <- make_raw_plots(file_list, "G-Criterion L-SHADE Comparison"))
ggsave("Plots/g_crit_comp.pdf", height = 6, width = 8, units = "in")

file_list <- c("L-SHADE-pure/D_sim.csv",
               "../PSO_OptDoE_development/PSO-full/D_sim.csv"
               )

(box_out <- make_raw_plots(file_list, "D-Criterion L-SHADE Comparison"))
ggsave("Plots/d_crit_comp.pdf", height = 6, width = 8, units = "in")


################ average_plots

criterion_file_lists <- list(
  "D-Criterion" = c("L-SHADE-pure/D_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/D_sim.csv"),
  "I-Criterion" = c("L-SHADE-pure/I_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/I_sim.csv"),
  "A-Criterion" = c("L-SHADE-pure/A_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/A_sim.csv"),
  "G-Criterion" = c("L-SHADE-pure/G_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/G_sim.csv")
)

(line_out <- make_average_plots(criterion_file_lists))
ggsave("Plots/criteria_av.pdf", plot = line_out, height = 6, width = 9, units = "in")


##################### 95% plots


criterion_file_lists <- list(
  "D-Criterion" = c("L-SHADE-pure/D_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/D_sim.csv"),
  "I-Criterion" = c("L-SHADE-pure/I_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/I_sim.csv"),
  "A-Criterion" = c("L-SHADE-pure/A_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/A_sim.csv"),
  "G-Criterion" = c("L-SHADE-pure/G_sim.csv",
                    "../PSO_OptDoE_development/PSO-full/G_sim.csv")
)

(line_out <- make_95_plots(criterion_file_lists))
ggsave("Plots/criteria_95.pdf", plot = line_out, height = 6, width = 9, units = "in")




# legend <- as_ggplot(get_legend(box_out))
# 
# ggsave("Plots/legend.pdf", legend, height = .5, width = 3, units = "in")
