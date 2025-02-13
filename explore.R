library(tidyverse)
library(ggplot2)
library(lubridate)

setwd('/Users/jakeevans/repos/byu/is555/group_project/spotify-data')

raw <- read_csv('data/19_train.csv')

# Notes on some of the columns (Taken from Spotify Documentation - https://developer.spotify.com/documentation/web-api/reference/get-audio-features)

# 1. Danceability - Describes suitability for dancing based on tempo, rhythm stability, beat strength, and regularity
# 2. Acousticness - Confidence measure of whether track is acoustic (1 represents high confidence that it is acoustic)
# 3. Energy - Features contributing include dynamic range, perceived loudness (LUF), timbre, onset rate, general entropy
# 4. Key - Starts with C = 0, C#/Db = 1, ... B = 1. If no key is detected, value is -1 (https://en.wikipedia.org/wiki/Pitch_class)
# 5. Loudness - Overall loudness of track in decibels (dB). Averaged across track, typically between -60 and 0 db
# 6. Instrumentalness - Predicts whether a track contains no vocals. (Ooh/aah are instrumental). Closer to 1, more likely it's Zimmer
# 7. Mode - Modality of track. Major is 1, Minor is 0... guess the other ones aren't important enough
# 8. Speechiness - Presence of spoken words. 0.666 and above is probably all words. 0.333 and below probably all music.
# 9. Liveness - Detects audience in recording. Higher value indicates that track was probably recorded live
# 10. Valence - Measure that describes the musical positiveness conveyed by a track. Cheerful, happy songs are closer to 1. Low valence (< 0.5) sounds angry, sad


# Exploratory Data Analysis

# Austin: Investigate dependent variable correlations

setwd('./555/spotify-analytics/data/')

#MODE AND KEY ARE CATEGORICAL

sample <- slice_sample(raw, prop = .4)

numeric_plot <- raw %>% 
  distinct() %>% 
  select(track_popularity, danceability, acousticness, energy, loudness, instrumentalness, speechiness, liveness, valence) %>% 
  pivot_longer(
    cols = c(danceability, acousticness, energy, loudness, instrumentalness, speechiness, liveness, valence),
    names_to = 'metric',
    values_to = 'value'
  ) %>% 
  ggplot(aes(y = track_popularity, x = value, fill = metric, color = metric)) +
  geom_point(alpha = 0.05) +
  facet_wrap(~metric, scales = 'free') + 
  theme_bw()

# Genres

genres_plot <- raw %>% 
  distinct() %>%
  select(track_popularity, playlist_genre, playlist_subgenre) %>% 
  pivot_longer(
    cols = c(playlist_genre, playlist_subgenre),
    names_to = 'metric',
    values_to = 'value'
  ) %>% 
  ggplot(aes(y = track_popularity, x = value, fill=value)) +
  geom_violin() +
  facet_wrap(~metric, scales = 'free', ncol = 1) + 
  theme_bw()

#Key and Mode

key_mode_plot <- raw %>% 
  distinct() %>%
  mutate(key = as.character(key), mode = as.character(mode)) %>% 
  select(track_popularity, key, mode) %>% 
  pivot_longer(
    cols = c(key, mode),
    names_to = 'metric',
    values_to = 'value'
  ) %>% 
  ggplot(aes(y = track_popularity, x = value, fill=value)) +
  geom_violin() +
  facet_wrap(~metric, scales = 'free', ncol = 1) + 
  theme_bw()

# Release Date

# Months have a few more values we can extract that this fails to capture but this is sufficient for exploration
dates <- raw %>% 
  distinct() %>% 
  select(track_popularity, track_album_release_date) %>% 
  mutate(formatted_date = ymd(track_album_release_date)) %>% 
  mutate(year = if_else(!is.na(formatted_date),year(formatted_date),year(as.numeric(substr(track_album_release_date, 1, 4)))), month = month(formatted_date))

year_plot <- dates %>% 
  mutate(year_chr = as.character(year)) %>% 
  ggplot(aes(x = year_chr, y = track_popularity, fill = year_chr)) +
  geom_violin() +
  theme_bw()

month_plot <- dates %>% 
  mutate(month_chr = as.character(month)) %>% 
  ggplot(aes(x = month_chr, y = track_popularity, fill = month_chr)) +
  geom_violin() +
  theme_bw()


dates %>% 
  group_by(month) %>% 
  summarize(count = n()) %>% 
  print(n=200)

dates %>% 
  filter(is.na(year))

raw %>% 
  group_by(track_album_release_date) %>% 
  summarize() %>% 
  print(n=3000)


# Spencer: Summarize the characteristics of the remaining variables in the dataset at a high level

raw <- read_csv('https://www.dropbox.com/scl/fi/2bbujng7y0dxpj8blb4ej/19_train.csv?rlkey=k8pxvbva2jwr0qp7oj1cc9ul5&dl=1')

colnames(raw)

raw %>% 
  glimpse

raw %>% 
  count(track_name) %>% 
  arrange(desc(n))

raw %>% 
  select(track_album_release_date) %>% 
  print(n = 50)

#Like variables:---------------------------------------------------------------------------------------------------
calculate_jaccard_similarity <- function(df) {
  num_cols <- ncol(df)
  
  # Initialize a matrix to store the Jaccard similarities
  similarity_matrix <- matrix(0, ncol = num_cols, nrow = num_cols, dimnames = list(names(df), names(df)))
  
  # Calculate Jaccard similarity for each pair of columns
  for (i in 1:(num_cols - 1)) {
    for (j in (i + 1):num_cols) {
      intersection <- sum(df[, i] == df[, j] & !is.na(df[, i]) & !is.na(df[, j]))
      union <- sum(!is.na(df[, i])) + sum(!is.na(df[, j])) - intersection
      
      # Calculate Jaccard similarity index
      jaccard_similarity <- intersection / union
      
      # Store the result in the matrix
      similarity_matrix[i, j] <- jaccard_similarity
      similarity_matrix[j, i] <- jaccard_similarity
    }
  }
  
  return(similarity_matrix)
}

result_matrix <- calculate_jaccard_similarity(df)

result_df <- as.data.frame(as.table(result_matrix))

jaccard_similarity_plot <- ggplot(result_df, aes(Var1, Var2, fill = Freq)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(title = "Jaccard Similarity between Variables",
       x = "Variable 1", y = "Variable 2") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))

#Number of categorical vs continuous variables-----------------------------------------------------------------------------------------------------------------------------------------------
raw %>%
  summarise_all(class) %>%
  gather(original_column, data_type) %>% 
  print(n = 30)

#Relevant patterns of missingness or odd distributions---------------------------------------------------------------------------------------------------------------------------------------

#Rows with any missing data
missing <- raw %>% 
  subset(!complete.cases(raw)) 
missing

#Double check missing data
raw %>%
  filter(!complete.cases(.))

#If key = -1, no key was detected. this code checks for any key values that weren't found
raw %>% 
  filter(key < 0)

raw %>% 
  select(key) %>% 
  arrange(key)


#No track popularity
raw %>% 
  filter(track_popularity == 0)

#Numeric Columns

#energy
raw %>% 
  select(energy) %>% 
  print(n = 200)

raw %>% 
  select(energy) %>% 
  summary(raw)

energy_plot <- raw %>%
  ggplot(aes(x = energy)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "energy",
  ) +
  theme_bw()

#instrumentalness
raw %>% 
  select(instrumentalness) %>% 
  summary(raw)

instrumentalness_plot <- raw %>%
  ggplot(aes(x = instrumentalness)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "instrumentalness",
  ) +
  theme_bw()

#tempo
raw %>% 
  select(tempo) %>% 
  summary(raw)

tempo_plot <- raw %>%
  ggplot(aes(x = tempo)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "tempo",
  ) +
  theme_bw()

raw %>% 
  select(tempo) %>% 
  arrange(tempo)

raw %>% 
  filter(tempo == 0)

#speechiness
speechiness_plot <- raw %>%
  ggplot(aes(x = speechiness)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "speechiness",
  ) +
  theme_bw()

#liveness
liveness_plot <- raw %>%
  ggplot(aes(x = liveness)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "liveness",
  ) +
  theme_bw()

#duration_ms
duration_minutes_plot <- raw %>%
  mutate(duration_minutes = duration_ms / (1000 * 60)) %>%
  ggplot(aes(x = duration_minutes)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "Duration in Minutes",
  ) +
  theme_bw()


#danceability
danceability_plot <- raw %>%
  ggplot(aes(x = danceability)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "danceability",
  ) +
  theme_bw()

#loudness
loudness_plot <- raw %>%
  ggplot(aes(x = loudness)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "loudness",
  ) +
  theme_bw()

raw %>% 
  select(loudness) %>% 
  summary(raw)

raw %>% 
  select(loudness) %>% 
  arrange(loudness)

#acousticness
acousticness_plot <- raw %>%
  ggplot(aes(x = acousticness)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "acousticness",
  ) +
  theme_bw()

#valence
valence_plot <- raw %>%
  ggplot(aes(x = valence)) +
  geom_histogram(bins = 15, alpha = 0.5) +
  labs(
    title = "valence",
  ) +
  theme_bw()

#Categorical Columns

#key
key_plot <- raw %>%
  ggplot(aes(x = key)) +
  geom_bar(fill = "skyblue", alpha = 0.7) +
  labs(
    title = "key",
  ) +
  theme_minimal()

#mode
mode_plot <- raw %>%
  ggplot(aes(x = mode)) +
  geom_bar(fill = "skyblue", alpha = 0.7) +
  labs(
    title = "mode",
  ) +
  theme_minimal()

#playlist_genre
playlist_genre_plot <- raw %>%
  ggplot(aes(x = playlist_genre)) +
  geom_bar(fill = "skyblue", alpha = 0.7) +
  labs(
    title = "playlist_genre",
  ) +
  theme_minimal()

#playlist_subgenre
playlist_subgenre_plot <- raw %>%
  ggplot(aes(x = playlist_subgenre)) +
  geom_bar(fill = "skyblue", alpha = 0.7) +
  labs(
    title = "playlist_subgenre",
  ) +
  theme_minimal()

#track_name
track_name_plot <- raw %>%
  ggplot(aes(x = track_name)) +
  geom_bar(fill = "skyblue", alpha = 0.7) +
  labs(
    title = "track_name",
  ) +
  theme_minimal()

#High level overview-----------------------------------------------------------------------------------------------------------------------------------------------
summary(raw)

df[sample(nrow(df), 10), ]


# Jake: Examine effects of independent vars on dependent

library(corrr)

# Here are all the columns in the database

# Explore dependent variable
raw %>% glimpse()
raw %>% filter(track_popularity > 98)

summary_stats <- summary(raw$track_popularity)
summary_sta

sample %>% 
ggplot(aes(x=track_popularity, fill=track_popularity)) +
geom_histogram(fill="orange", alpha=0.6) +
  theme_bw()

# Numeric variables
numeric_vars <- raw %>% 
  select_if(is.numeric) %>% 
  select(-mode, -key) %>% 
  colnames()
numeric_vars

df_numeric <- raw %>% 
  select(all_of(numeric_vars))

correlation <- df_numeric %>% select(all_of(numeric_vars)) %>% 
  correlate()
rplot(correlation)

matrix <- cor(df_numeric, method=c("pearson"))

library(corrplot)
corrplot(matrix, type="upper", tl.col="black")

# Categorical variables (mode and key)
key_labels <- c("C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab", "A", "A#/Bb", "B")

raw %>% 
  mutate(key = factor(key, levels = 0:11, labels=key_labels)


# Old EDA (Used by work ^^^^)

# Look at shape and column types
raw %>% glimpse()

# We have 5 missing values
missing <- raw %>% 
  subset(!complete.cases(raw)) 
missing

# Find duplicates across all rows
duplicated <- sum(duplicated(raw))
duplicated

# Find duplicates by track_id - looks like songs that appear in more than 1 playlist are duplicated here
filtered_duplicates <- raw %>%
  filter(duplicated(track_id) | duplicated(track_id, fromLast = TRUE)) %>%
  arrange(track_id)
filtered_duplicates

# Basic univariate analysis
summary(raw)

# Unique track count
num_unique_tracks <- raw %>% 
  summarise(unique_tracks = n_distinct(track_id))
num_unique_tracks

# Genre count
genre_count <- raw %>%
  count(playlist_genre) %>% arrange(desc(n))
genre_count

# Sub-genre count
subgenre_count <- raw %>% 
  count(playlist_subgenre)
subgenre_count %>% arrange(desc(n)) %>% print(n=30) 

# Top 10 artists with song counts
top_ten_artists <- raw %>% 
  select(track_artist, track_id)
top_ten_artists %>% group_by(track_artist) %>% summarise(num_tracks = n_distinct(track_id)) %>% arrange(desc(num_tracks)) %>% head(10)

# Find invalid values for range attributes
rows_outside_range <- raw %>%
  filter(valence > 1 | valence < 0,
         liveness > 1 | liveness < 0,
         speechiness > 1 | speechiness < 0,
         loudness > 1 | loudness < 0,
         acousticness > 1 | acousticness < 0,
         instrumentalness > 1 | instrumentalness < 0)
rows_outside_range



##### Data Cleanup and Standardization

library(lubridate)

raw

# Remove Null values - should result in 24,619 values
data_no_null <- raw %>% 
  filter(complete.cases(.))
data_no_null

missing <- data_no_null %>% 
  subset(!complete.cases(data_no_null)) 
missing

# convert track_album_release_date to date
date_fixed <- data_no_null %>% 
  mutate(track_album_release_date = as.Date(track_album_release_date))
date_fixed

clean_data <- date_fixed


### TODO: Fix duplicates



### Data Visualizations


clean_data %>% 
  ggplot(aes(x=track_popularity)) +
  geom_histogram(fill="skyblue")
  

