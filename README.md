MAD 4360 — Activity 10: Flutter Signup Form Quest
Project Information

App: PawPals Signup
Course: MAD 4360
Activity: 10 — Flutter Forms
Track: Undergraduate
Student name(s): [Enter name(s)]
Repository: https://github.com/sniggy2610-05/inc10
App Features

Signup form with name, email, and password validation.
Confirm-password field and personalized success message.
Local password-strength guidance.
AI Signup Coach with loading, result, error, and retry states.
Scrollable layout and personalized Material theme.
AI Request and Privacy

The intended request contains only:

task: signup_tip
topic: password_help
The request does not include the user's name, email, or password.

Service mode: [Live instructor service / Mock fallback]

If using the mock: State clearly that no live AI model was called.

Testing Results

Record the actual result of each test.


Test	Result
Empty signup fields	[Pass/Fail and observation]
Invalid email	[Pass/Fail and observation]
Password shorter than 6 characters	[Pass/Fail and observation]
Valid signup input	[Pass/Fail and observation]
AI tip success	[Pass/Fail and observation]
AI offline/error and retry	[Pass/Fail and observation]
Privacy boundary	[Describe what you verified]
APK build	[Release/debug and result]
Undergraduate Reflection

Question 1

Trace the AI tip feature from button tap to displayed text. Which widget/state changes while the request is waiting, and how does the user recover if it fails?

My answer: [Explain your implementation and your observations.]

Question 2

Why must the app keep form validation local even when it can ask an AI for a tip? Give one example of a bad decision if AI were allowed to approve signup.

My answer: [Explain in your own words.]

Contributions

My contribution: [Describe the code, testing, and changes you personally completed.]
Partner contribution, if applicable: [Describe their actual contribution.]
Limitations and Improvements

[Describe one limitation you observed and one improvement you would make.]