package calls

import (
	"fmt"
	"goDial/internal/templates/pages"
	"net/http"
	"strconv"
)

type callForm struct {
	recipientNumber string
	recipientName   string
	objective       string
	otherContext    string
}

// HandleCallProcedure handles our route, and returns the home page currently. However, what we want to do is return something like a 'call-status' page, where they can observe things like if the call is finished, its review after completion, etc.. From this function, we want to check the form values, log it to the db, and also begin the call procedure of starting the actual call.
func HandleCallProcedure(w http.ResponseWriter, r *http.Request) {
	err := validateCallForm(r)
	if err != nil {
		w.WriteHeader(400) // TODO: figure out bad req
		fmt.Printf("error taking user form to make a call, form not valid: %v\n", err)
		return
	}

	pages.Home().Render(r.Context(), w) // change to return call-status page
}

func validateCallForm(r *http.Request) error {

	phoneNum, recipientInfo, objective, otherContext := r.FormValue("recipientPhoneNumber"), r.FormValue("recipientContext"), r.FormValue("objective"), r.FormValue("otherContext")

	err := validatePhoneNumber(phoneNum)
	if err != nil {
		return fmt.Errorf("error validating phoneNum from user, %s: %w", phoneNum, err)
	}

	thisCallData := callForm{

		recipientNumber: phoneNum,
		recipientName:   recipientInfo,
		objective:       objective,
		otherContext:    otherContext,
	}

	return nil
}

// validatePhoneNumber is meant to check for errors with the phone number received from the user.
// Signalwire requires it to be an int, so we don't return an int, no need
func validatePhoneNumber(number string) error {
	_, err := strconv.Atoi(number)
	if err != nil {
		return fmt.Errorf("error converting phone number from user into integer: %w\n", err)
	}

	if len(number) != 10 {
		return fmt.Errorf("error with phone number from user, not 10 digits as requred: %s\n", number)
	}

	return nil
}
