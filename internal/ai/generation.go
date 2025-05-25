package ai

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
)

// CallAnthropic function takes in any string, and responds with a generated Anthropic response in a string.
func CallAnthropic(prompt string) (string, error) {
	// Get API key from environment variable
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		return "", fmt.Errorf("ANTHROPIC_API_KEY environment variable not set")
	}

	// Create client with the api key we have
	client := anthropic.NewClient(
		option.WithAPIKey(apiKey),
	)

	// creates a new user message in the message json struct anthropic uses
	messages := []anthropic.MessageParam{
		anthropic.NewUserMessage(anthropic.NewTextBlock(prompt)),
	}

	// get response from anthropic, adding it to messages struct
	message, err := client.Messages.New(context.TODO(), anthropic.MessageNewParams{
		Model:     anthropic.ModelClaude3_7SonnetLatest,
		Messages:  messages,
		MaxTokens: 1024,
	})
	if err != nil {
		return "", fmt.Errorf("error creating new anthropic client messages: %w\n", err)
	}

	messages = append(messages, message.ToParam())
	messages = append(messages, anthropic.NewUserMessage(
		anthropic.NewTextBlock(prompt),
	))

	// from the json that Antropic returns, build the response
	var generatedResponse strings.Builder
	for _, jsonBlock := range message.Content {
		if jsonBlock.Type != "text" {
			fmt.Printf("error, response from anthropic was not of type \"type\" test. Type: %s\n", message.Content[0].Type)
		}
		generatedResponse.WriteString(jsonBlock.Text)
	}
	return generatedResponse.String(), nil
}

// checking if user input is an input we're comfortable excecuting based on the prompt.
// returns an empty string if the request was good, else, has the reason the request was bad.
func CheckPromptValidity(userPrompt string) (string, error) {
	resp, err := CallAnthropic("below is a request the user has asked an employee to complete. we have a phone number, and then this set of instructions. Your job is to *only* respond with either, 'true', or explain why you dont think the request is valid. You will respond with true if you feel that the request is in no way harmful to complete, does not contain legal implications in any US state. If you feel we may have any ethical concerns, please respond with nothing more than you reason for thinking the request may not be valid..." + userPrompt)
	if err != nil {
		return "error in call anthropic...", fmt.Errorf("error calling anthropic: %v\n", err)
	}
	if resp != "true" {
		return fmt.Sprintf(
				"anthropic has detected that for some reason, the request was invalid... see here: %s\n", resp,
			),
			fmt.Errorf(
				"anthropic has detected that for some reason, the request was invalid... see here: %s\n", resp,
			)
	}
	return "", nil
}
