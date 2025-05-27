package stripe

import (
	"fmt"
	"os"
)

func GetStripePaymentForm() {
	myStripeKey := os.Getenv("STRIPE_SECRET_API_KEY")
	fmt.Println(myStripeKey)

}
