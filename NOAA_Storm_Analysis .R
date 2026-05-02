# NOAA Storm Events Database 
# Final Course Project

packages_needed <- c("dplyr", "readr", "ggplot2", "forcats", "stringr",
                     "tidyr", "scales", "knitr",
                     "gridExtra", "ggrepel")

for (pkg in packages_needed) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}
install.packages("PKI", type = "binary")
install.packages("rsconnect", type = "binary")
folder_path <- "~/Desktop/R"   
details_file    <- file.path(folder_path, "StormEvents_details-ftp_v1.0_d2025_c20260323 (1).csv")
fatalities_file <- file.path(folder_path, "StormEvents_fatalities-ftp_v1.0_d2025_c20260323.csv")
locations_file  <- file.path(folder_path, "StormEvents_locations-ftp_v1.0_d2025_c20260323 2.csv")

details    <- read_csv(details_file,    show_col_types = FALSE)
fatalities <- read_csv(fatalities_file, show_col_types = FALSE)
locations  <- read_csv(locations_file,  show_col_types = FALSE)

cat("Details rows   :", nrow(details),    "\n")
cat("Fatalities rows:", nrow(fatalities), "\n")
cat("Locations rows :", nrow(locations),  "\n")

StormEvents_joined_data <- details %>%
  left_join(locations,  by = "EVENT_ID") %>%
  left_join(fatalities, by = "EVENT_ID")

output_file <- file.path(folder_path, "StormEvents_joined_data.csv")
write_csv(StormEvents_joined_data, output_file)
message("Joined data saved to: ", output_file)

print(head(StormEvents_joined_data))

parse_damage <- function(x) {
  x <- as.character(x)
  multiplier <- dplyr::case_when(
    stringr::str_detect(x, "K") ~ 1e3,
    stringr::str_detect(x, "M") ~ 1e6,
    stringr::str_detect(x, "B") ~ 1e9,
    TRUE ~ 1
  )
  numeric_part <- as.numeric(stringr::str_remove_all(x, "[KMBkmb ]"))
  ifelse(is.na(numeric_part), 0, numeric_part * multiplier)
}

storm <- details %>%
  mutate(
    DAMAGE_PROPERTY_NUM = parse_damage(DAMAGE_PROPERTY),
    DAMAGE_CROPS_NUM    = parse_damage(DAMAGE_CROPS),
    TOTAL_DAMAGE        = DAMAGE_PROPERTY_NUM + DAMAGE_CROPS_NUM,
    TOTAL_INJURIES      = INJURIES_DIRECT + INJURIES_INDIRECT,
    TOTAL_DEATHS        = DEATHS_DIRECT   + DEATHS_INDIRECT,
    HEALTH_IMPACT       = TOTAL_INJURIES  + TOTAL_DEATHS,
    MONTH_NAME = factor(MONTH_NAME,
                        levels = c("January","February","March","April",
                                   "May","June","July","August",
                                   "September","October","November","December"))
  )

top_deaths <- storm %>%
  group_by(EVENT_TYPE) %>%
  summarise(TOTAL_DEATHS = sum(TOTAL_DEATHS), .groups = "drop") %>%
  arrange(desc(TOTAL_DEATHS)) %>%
  slice_head(n = 15) %>%
  mutate(EVENT_TYPE = forcats::fct_reorder(EVENT_TYPE, TOTAL_DEATHS))

top_injuries <- storm %>%
  group_by(EVENT_TYPE) %>%
  summarise(TOTAL_INJURIES = sum(TOTAL_INJURIES), .groups = "drop") %>%
  arrange(desc(TOTAL_INJURIES)) %>%
  slice_head(n = 15) %>%
  mutate(EVENT_TYPE = forcats::fct_reorder(EVENT_TYPE, TOTAL_INJURIES))

p_deaths <- ggplot(top_deaths, aes(x = TOTAL_DEATHS, y = EVENT_TYPE)) +
  geom_col(fill = "#C0392B", alpha = 0.85) +
  geom_text(aes(label = TOTAL_DEATHS), hjust = -0.1, size = 3.2) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Fatalities by Event Type", x = "Total Deaths", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        panel.grid.major.y = element_blank())

p_injuries <- ggplot(top_injuries, aes(x = TOTAL_INJURIES, y = EVENT_TYPE)) +
  geom_col(fill = "#E67E22", alpha = 0.85) +
  geom_text(aes(label = TOTAL_INJURIES), hjust = -0.1, size = 3.2) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Injuries by Event Type", x = "Total Injuries", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        panel.grid.major.y = element_blank())

gridExtra::grid.arrange(p_deaths, p_injuries, ncol = 2)

top_states <- storm %>% count(STATE, sort = TRUE) %>% slice_head(n = 15) %>% pull(STATE)
top_events <- storm %>% count(EVENT_TYPE, sort = TRUE) %>% slice_head(n = 15) %>% pull(EVENT_TYPE)

heatmap_data <- storm %>%
  filter(STATE %in% top_states, EVENT_TYPE %in% top_events) %>%
  count(STATE, EVENT_TYPE) %>%
  mutate(
    STATE      = factor(STATE,      levels = rev(top_states)),
    EVENT_TYPE = factor(EVENT_TYPE, levels = top_events)
  )

ggplot(heatmap_data, aes(x = EVENT_TYPE, y = STATE, fill = n)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = ifelse(n >= 50, scales::comma(n), "")),
            size = 2.6, color = "white", fontface = "bold") +
  scale_fill_gradient(low = "#D6EAF8", high = "#1A5276",
                      name = "Event Count", labels = scales::comma) +
  scale_x_discrete(guide = guide_axis(angle = 40)) +
  labs(title = "Storm Event Frequency by State and Event Type (Top 15 Each), 2025",
       x = "Event Type", y = "State") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

top8_events <- storm %>% count(EVENT_TYPE, sort = TRUE) %>% slice_head(n = 8) %>% pull(EVENT_TYPE)

monthly_data <- storm %>%
  filter(EVENT_TYPE %in% top8_events) %>%
  count(EVENT_TYPE, MONTH_NAME) %>%
  tidyr::complete(EVENT_TYPE, MONTH_NAME, fill = list(n = 0))

ggplot(monthly_data, aes(x = MONTH_NAME, y = n, fill = EVENT_TYPE)) +
  geom_col(show.legend = FALSE, alpha = 0.85) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_discrete(guide = guide_axis(angle = 45)) +
  facet_wrap(~ EVENT_TYPE, scales = "free_y", ncol = 2) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Monthly Distribution of Top 8 Storm Event Types, 2025",
       x = NULL, y = "Number of Events") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold"))

top_damage <- storm %>%
  group_by(EVENT_TYPE) %>%
  summarise(TOTAL_DAMAGE = sum(TOTAL_DAMAGE), .groups = "drop") %>%
  filter(TOTAL_DAMAGE > 0) %>%
  arrange(desc(TOTAL_DAMAGE)) %>%
  slice_head(n = 15) %>%
  mutate(EVENT_TYPE = forcats::fct_reorder(EVENT_TYPE, TOTAL_DAMAGE),
         DAMAGE_M   = TOTAL_DAMAGE / 1e6)

ggplot(top_damage, aes(x = DAMAGE_M, y = EVENT_TYPE)) +
  geom_col(fill = "#1F618D", alpha = 0.85) +
  geom_text(aes(label = paste0("$", round(DAMAGE_M, 1), "M")),
            hjust = -0.05, size = 3.2) +
  scale_x_continuous(labels = scales::dollar_format(suffix = "M"),
                     expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Top 15 Weather Events by Total Economic Damage, 2025",
       x = "Total Damage (USD Millions)", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        panel.grid.major.y = element_blank())

if (!requireNamespace("ggrepel", quietly = TRUE)) install.packages("ggrepel")
library(ggrepel)

risk_data <- storm %>%
  group_by(EVENT_TYPE) %>%
  summarise(n_events     = n(),
            total_deaths = sum(TOTAL_DEATHS),
            avg_deaths   = mean(TOTAL_DEATHS),
            total_damage = sum(TOTAL_DAMAGE),
            .groups = "drop") %>%
  filter(n_events >= 20, total_damage > 0) %>%
  arrange(desc(total_damage + total_deaths * 1e5)) %>%
  slice_head(n = 25)

ggplot(risk_data,
       aes(x = total_damage / 1e6, y = avg_deaths,
           size = n_events, color = avg_deaths, label = EVENT_TYPE)) +
  geom_point(alpha = 0.75) +
  ggrepel::geom_text_repel(size = 2.8, max.overlaps = 25) +
  scale_x_log10(labels = scales::dollar_format(suffix = "M")) +
  scale_size_continuous(name = "Event Count", range = c(2, 14)) +
  scale_color_gradient(low = "#F9E79F", high = "#C0392B",
                       name = "Avg Deaths\nper Event") +
  labs(title = "Weather Event Risk Profile: Health Lethality vs. Economic Damage",
       x = "Total Economic Damage (USD Millions, log scale)",
       y = "Average Deaths per Event") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

