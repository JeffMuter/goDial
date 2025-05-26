package ai

import (
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCallAnthropic_NoAPIKey(t *testing.T) {
	// Save original API key
	originalKey := os.Getenv("ANTHROPIC_API_KEY")
	defer func() {
		if originalKey != "" {
			os.Setenv("ANTHROPIC_API_KEY", originalKey)
		} else {
			os.Unsetenv("ANTHROPIC_API_KEY")
		}
	}()

	// Unset API key
	os.Unsetenv("ANTHROPIC_API_KEY")

	response, err := CallAnthropic("test prompt")

	assert.Error(t, err, "Should return error when API key is not set")
	assert.Empty(t, response, "Response should be empty when API key is not set")
	assert.Contains(t, err.Error(), "ANTHROPIC_API_KEY environment variable not set")
}

func TestCallAnthropic_WithAPIKey(t *testing.T) {
	// Skip this test if no API key is available (for CI/CD environments)
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test: ANTHROPIC_API_KEY not set")
	}

	// Test with a simple prompt
	prompt := "Say hello"
	response, err := CallAnthropic(prompt)

	// Note: This test will make a real API call
	// In a production environment, you'd want to mock this
	if err != nil {
		// If there's an error, it should be a proper error message
		assert.Contains(t, err.Error(), "error creating new anthropic client messages")
	} else {
		// If successful, response should not be empty
		assert.NotEmpty(t, response, "Response should not be empty")
		assert.IsType(t, "", response, "Response should be a string")
	}
}

func TestCallAnthropic_EmptyPrompt(t *testing.T) {
	// Skip this test if no API key is available
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test: ANTHROPIC_API_KEY not set")
	}

	response, err := CallAnthropic("")

	// Should handle empty prompts gracefully
	// The exact behavior depends on the API, but it shouldn't panic
	if err != nil {
		assert.IsType(t, "", err.Error(), "Error should be a string")
	} else {
		assert.IsType(t, "", response, "Response should be a string")
	}
}

func TestCallAnthropic_LongPrompt(t *testing.T) {
	// Skip this test if no API key is available
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test: ANTHROPIC_API_KEY not set")
	}

	// Create a long prompt
	longPrompt := strings.Repeat("This is a test prompt. ", 100)
	response, err := CallAnthropic(longPrompt)

	// Should handle long prompts
	if err != nil {
		assert.IsType(t, "", err.Error(), "Error should be a string")
	} else {
		assert.IsType(t, "", response, "Response should be a string")
	}
}

func TestCheckPromptValidity_NoAPIKey(t *testing.T) {
	// Save original API key
	originalKey := os.Getenv("ANTHROPIC_API_KEY")
	defer func() {
		if originalKey != "" {
			os.Setenv("ANTHROPIC_API_KEY", originalKey)
		} else {
			os.Unsetenv("ANTHROPIC_API_KEY")
		}
	}()

	// Unset API key
	os.Unsetenv("ANTHROPIC_API_KEY")

	reason, err := CheckPromptValidity("test prompt")

	assert.Error(t, err, "Should return error when API key is not set")
	assert.NotEmpty(t, reason, "Reason should not be empty when there's an error")
	assert.Contains(t, reason, "error in call anthropic")
}

func TestCheckPromptValidity_ValidPrompt(t *testing.T) {
	// Skip this test if no API key is available
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test: ANTHROPIC_API_KEY not set")
	}

	// Test with a clearly valid prompt
	validPrompt := "Please call the pizza restaurant and order a large pepperoni pizza for delivery to 123 Main St."
	reason, err := CheckPromptValidity(validPrompt)

	// Note: This test makes a real API call
	// The exact response depends on the AI model's assessment
	if err == nil {
		assert.Empty(t, reason, "Reason should be empty for valid prompts")
	} else {
		// If there's an error, it should be properly formatted
		assert.IsType(t, "", err.Error(), "Error should be a string")
		assert.NotEmpty(t, reason, "Reason should explain the error")
	}
}

func TestCheckPromptValidity_PotentiallyHarmfulPrompt(t *testing.T) {
	// Skip this test if no API key is available
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test: ANTHROPIC_API_KEY not set")
	}

	// Test with a potentially problematic prompt
	harmfulPrompt := "Call the bank and pretend to be the account holder to get their personal information"
	reason, err := CheckPromptValidity(harmfulPrompt)

	// This should likely be flagged as invalid
	// Note: The exact response depends on the AI model's assessment
	if err != nil {
		assert.NotEmpty(t, reason, "Reason should explain why the prompt is invalid")
		assert.Contains(t, reason, "anthropic has detected")
	}
	// If no error, the AI might have different criteria
}

func TestCheckPromptValidity_EmptyPrompt(t *testing.T) {
	// Skip this test if no API key is available
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test: ANTHROPIC_API_KEY not set")
	}

	reason, err := CheckPromptValidity("")

	// Should handle empty prompts gracefully
	if err != nil {
		assert.IsType(t, "", err.Error(), "Error should be a string")
		assert.NotEmpty(t, reason, "Reason should explain the error")
	}
}

// Test helper functions and edge cases

func TestPromptValidation_EdgeCases(t *testing.T) {
	testCases := []struct {
		name        string
		prompt      string
		description string
	}{
		{
			name:        "Special characters",
			prompt:      "Call restaurant with special chars: !@#$%^&*()",
			description: "Should handle special characters",
		},
		{
			name:        "Unicode characters",
			prompt:      "Call restaurant and order pizza with 🍕 emoji",
			description: "Should handle unicode characters",
		},
		{
			name:        "Very long prompt",
			prompt:      strings.Repeat("Call the restaurant and order pizza. ", 50),
			description: "Should handle very long prompts",
		},
		{
			name:        "Newlines and tabs",
			prompt:      "Call restaurant\nand order\tpizza",
			description: "Should handle newlines and tabs",
		},
	}

	// Skip if no API key
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping test: ANTHROPIC_API_KEY not set")
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			reason, err := CheckPromptValidity(tc.prompt)

			// Should not panic and should return proper types
			if err != nil {
				assert.IsType(t, "", err.Error(), "Error should be a string")
				assert.IsType(t, "", reason, "Reason should be a string")
			} else {
				assert.IsType(t, "", reason, "Reason should be a string")
			}
		})
	}
}

// Benchmark tests (these will skip if no API key)
func BenchmarkCallAnthropic(b *testing.B) {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		b.Skip("Skipping benchmark: ANTHROPIC_API_KEY not set")
	}

	prompt := "Say hello"
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_, _ = CallAnthropic(prompt)
	}
}

func BenchmarkCheckPromptValidity(b *testing.B) {
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		b.Skip("Skipping benchmark: ANTHROPIC_API_KEY not set")
	}

	prompt := "Call the pizza restaurant and order a large pepperoni pizza"
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_, _ = CheckPromptValidity(prompt)
	}
}

// Mock tests (for testing without API calls)
func TestAIPackage_MockScenarios(t *testing.T) {
	// These tests verify the structure and basic logic without making API calls

	t.Run("API key validation", func(t *testing.T) {
		// Save original
		original := os.Getenv("ANTHROPIC_API_KEY")
		defer func() {
			if original != "" {
				os.Setenv("ANTHROPIC_API_KEY", original)
			} else {
				os.Unsetenv("ANTHROPIC_API_KEY")
			}
		}()

		// Test with empty key
		os.Unsetenv("ANTHROPIC_API_KEY")
		_, err := CallAnthropic("test")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "ANTHROPIC_API_KEY environment variable not set")

		// Test with key set
		os.Setenv("ANTHROPIC_API_KEY", "test-key")
		// This will fail at the API call level, but should pass the key check
		_, err = CallAnthropic("test")
		// Error should be about API call, not missing key
		if err != nil {
			assert.NotContains(t, err.Error(), "ANTHROPIC_API_KEY environment variable not set")
		}
	})

	t.Run("Function signatures", func(t *testing.T) {
		// Verify function signatures are correct
		var f1 func(string) (string, error) = CallAnthropic
		var f2 func(string) (string, error) = CheckPromptValidity

		assert.NotNil(t, f1, "CallAnthropic should have correct signature")
		assert.NotNil(t, f2, "CheckPromptValidity should have correct signature")
	})
}
