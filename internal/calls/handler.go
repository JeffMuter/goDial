package calls

import (
	"encoding/json"
	"fmt"
	"goDial/internal/ai"
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
	// validate & get data from the requests call form
	callFormData, err := validateCallForm(r)
	if err != nil {
		w.WriteHeader(400) // TODO: figure out bad req
		fmt.Printf("error taking user form to make a call, form not valid: %v\n", err)
		return
	}

	// format the prompt, and this should tell us if we *want* to do this task
	response, err := ai.CheckPromptValidity(fmt.Sprintf("user wants to contact:%s, user wants to accomplish: %s, user provided outside context: %s.", callFormData.recipientName, callFormData.objective, callFormData.otherContext))

	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)

		resp := map[string]interface{}{
			"error":   "forbidden",
			"message": "Request violates Terms of Service",
		}

		json.NewEncoder(w).Encode(resp)
	}

	// create prompt for the first thing to say to the user when they pick up the phone.

	// make the call

	pages.Home().Render(r.Context(), w) // change to return call-status page
}

// validateCallForm checks the request for call form values,
func validateCallForm(r *http.Request) (*callForm, error) {

	// getting form values, save to variables
	phoneNum, recipientInfo, objective, otherContext := r.FormValue("recipientPhoneNumber"), r.FormValue("recipientContext"), r.FormValue("objective"), r.FormValue("otherContext")

	// check basic lengths
	if len(phoneNum) == 0 || len(objective) == 0 || len(recipientInfo) == 0 {
		return nil, fmt.Errorf("error while validating call form data lengeth of phoneNum, objective, or recipientInfo: %d, %d, %d\n", len(phoneNum), len(objective), len(recipientInfo))
	}

	err := validatePhoneNumber(phoneNum)
	if err != nil {
		return nil, fmt.Errorf("error validating phoneNum from user, %s: %w", phoneNum, err)
	}

	thisCallData := callForm{
		recipientNumber: phoneNum,
		recipientName:   recipientInfo,
		objective:       objective,
		otherContext:    otherContext,
	}

	return &thisCallData, nil
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
