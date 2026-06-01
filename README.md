## Problem Statement
Baseball organizations generate large amounts of historical player, salary, and team data. The objective of this project was to analyze:
- Which schools produce the most professional players
- How team salary spending has evolved over time
- Which teams invest the most in player salaries
- Player career longevity and career paths
- Similarities between players
- Demographic trends across generations of players
The goal was to transform raw baseball data into actionable insights using advanced SQL.

## Dataset Tables
- Players
- Salaries
- Schools
- School Details

## Analysis Performed
### Part 1: School Analysis
Tasks:
- Determine how many schools produced players in each decade
- Identify the top schools producing professional players
- Find the top 3 player-producing schools for every decade

Key Insights:
- Certain schools consistently produced professional players across multiple decades.
- A small group of schools contributed a disproportionately large share of professional talent.
- School influence changed over time, with different institutions dominating different eras.

SQL Concepts Used:
- CTEs
- ROW_NUMBER()
- Ranking within groups
- Decade-based aggregation

### Part 2: Salary Analysis
Tasks:
- Calculate annual spending by team
- Identify the top 20% highest-spending teams
- Compute cumulative salary spending over time
- Find the first year each team surpassed $1 billion in total spending
  
Key Insights:
- Salary spending increased significantly over time across most teams.
- A small number of teams consistently outspent competitors.
- Several franchises crossed the $1 billion cumulative spending mark much earlier than others, indicating long-term financial dominance.
- Spending patterns highlighted competitive differences between teams.
  
SQL Concepts Used:
- NTILE()
- Running Totals
- Window Functions
- Aggregation
- Multi-level CTEs

### Part 3: Player Career Analysis
Tasks:
- Calculate player age at debut
- Calculate age at retirement
- Measure career length
- Identify teams players started and ended their careers with
- Find players who spent over a decade with the same team
  
Key Insights:
- Career lengths varied significantly among players.
- Some athletes maintained careers spanning multiple decades.
- Long-tenured players demonstrated strong team loyalty by starting and ending their careers with the same organization.
- Player debut ages remained relatively consistent across generations.
  
SQL Concepts Used:
- TIMESTAMPDIFF()
- Date Calculations
- Self-Joins
- Career Duration Analysis

### Part 4: Player Comparison Analysis
Tasks:
- Identify players sharing the same birthday
- Analyze batting-hand distribution by team
- Examine changes in player height and weight over time
- Calculate decade-over-decade physical attribute changes
  
Key Insights:
- Right-handed batters represented the majority of players across teams.
- Switch hitters remained a relatively small percentage of the player population.
- Average player height and weight increased over successive decades.
- Modern players tend to be larger and heavier than players from earlier generations.
  
SQL Concepts Used:
- GROUP_CONCAT()
- Conditional Aggregation
- CASE Statements
- LAG()
- Trend Analysis


### Strength:
- Joins
- Subqueries
- CTEs
- Window Functions
- CASE Statements
- Aggregate Functions

### Key SQL Functions Used
ROW_NUMBER()
NTILE()
LAG()
SUM() OVER()
COUNT()
AVG()
GROUP_CONCAT()
TIMESTAMPDIFF()
DATEDIFF()
CASE WHEN
CAST()
CONCAT()


### Project Outcomes
This project demonstrates the ability to solve real-world analytical problems using advanced SQL techniques.



## Note
- This project was completed as part of my SQL learning journey. 
- I independently wrote, tested, and refined the queries to answer business and analytical questions, strengthening my understanding of data exploration, performance analysis, and SQL-based reporting.
- To reinforce my understanding, I included comments throughout the SQL scripts for important takeaways. These notes serve both as documentation of my learning process and as a reference for future revision.



dataset source: Udemy - SQL for Data Analysis - Advanced SQL Querying Techniques (Maven Analytics)
