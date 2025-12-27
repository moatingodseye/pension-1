A dart shelf server and dart web flutter client.

The dart shelf server provides rest endpoints for accessing several tables in a SQLite database.

every table has a unique integer id.

users - (id, username, password, dob, is_admin, locked)
	dob - date of birth of the user
	
pension_pots table (id, name, amount, dated, interest_rate)
	name - name of the pension pot.
	user_id - this pot is for this user
	amount - the value of the pension at dated date.
	date - snapshot of the amount at this date
	interest_rate - yearly APR for the pension

There can be multiple pots defined per user

drawdowns table (id, pension_pot_id, amount, start_date, end_date, interest_rate)
	user_id - 
	pension_pot_id - this is a drawdown on this pot
	amount - monthly amount taken from the pot
	start_date - start of the drawdown
	end_date - end of the drawdown, this can be null meaning the drawdown continues indefinitely.
	interest_rate - yearly APR to increase this drawdown by to deal with inflation.

state_pensions - (id, user_id, start_age, amount, interest_rate)
	user_id - 
	start_age - the state pension starts at this age for the user indicated
	amount - the monthly income from the state
	interest_rate - increases by this yearly APR to deal with inflation

The web flutter application has crud for all of these tables.

It has a fl_chart output screen
	The server has a simulate end point which calculates the values for the chart.

The chart screen needs to show the following, hence the simulate must calculate the values needed for the chart.

	Show a line for each individual pension pot for the logged in user, the Y axis is to be the amount, the x axis to be the month/year. The origin should be the minimum date from all the pots of the user. The line should be labelled with the name of the pot.
	Show a line which is the sum of all the pot values for said user.
	Show a line the income for the user, the income is the sum of the drawdowns from the pots of the user, and the state_pension (if the user has reached the start_age of the pension).
	This the pension pots should be reducing by the amount of the drawdowns, and increasing my the amount of interest.
	The chart should show the minimum and maximum sum of pots from a monte carlo simulation of the pot performance over 100 years. Hence showing the likelihood of the target values being reached.
	