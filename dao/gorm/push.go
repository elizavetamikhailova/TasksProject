package gorm

import (
	"context"
	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"fmt"
	"github.com/douglasmakey/go-fcm"
	"log"
	"time"
)

func sendPush1(pushTokens []string) error {
	client := fcm.NewClient("AAAAKK98hI4:APA91bG-2zRyS7fOJg-isCmSVrvc6Vp5nRzZ12LFCtLdB83f_xjbIgPvKClSHvXYECQ4SOIJ-KRYi7MrSb1QI0AN1qDOndwypdSJBMpBYelXU4BX7cz-BHH-1v__8LBVlPiTceBM1GuM")
	data := map[string]interface{}{
		"message": "From Go-FCM",
	}
	client.PushMultiple(pushTokens, data)
	// registrationIds remove and return map of invalid tokens
	badRegistrations := client.CleanRegistrationIds()
	log.Println(badRegistrations)

	status, err := client.Send()
	if err != nil {
		log.Fatalf("error: %v", err)
		return err
	}

	log.Println(status.Results)
	println("STAAAAAAAAAAATUUUUUUUUS", status.Results)
	return nil
}

func sendPush(app *firebase.App, pushTokens []string) error {
	ctx := context.Background()
	client, err := app.Messaging(ctx)
	if err != nil {
		log.Fatalf("error getting Messaging client: %v\n", err)
		return err
	}

	message := &messaging.MulticastMessage{
		Data: map[string]string{
			"score": "850",
			"time":  "2:45",
		},
		Tokens: pushTokens,
	}

	br, err := client.SendMulticast(context.Background(), message)
	if err != nil {
		log.Fatalln(err)
		return err
	}

	// See the BatchResponse reference documentation
	// for the contents of response.
	fmt.Printf("%d messages were sent successfully\n", br.SuccessCount)
	return nil
}

func sendNotification(app *firebase.App, pushTokens []string) error {
	ctx := context.Background()
	client, err := app.Messaging(ctx)
	if err != nil {
		log.Fatalf("error getting Messaging client: %v\n", err)
		return err
	}

	for _, v := range pushTokens {
		messages := []*messaging.Message{
			{
				Notification: &messaging.Notification{
					Title: "Price drop",
					Body:  "5% off all electronics",
				},
				Token: v,
			},
		}

		br, err := client.SendAll(context.Background(), messages)
		if err != nil {
			log.Fatalln(err)
			return err
		}

		fmt.Printf("%d messages were sent successfully\n", br.SuccessCount)
	}
	return nil
}

func androidMessage(app *firebase.App, pushTokens []string) error {
	// [START android_message_golang]
	ctx := context.Background()
	client, err := app.Messaging(ctx)
	if err != nil {
		log.Fatalf("error getting Messaging client: %v\n", err)
		return err
	}

	for _, v := range pushTokens {
		oneHour := time.Duration(1) * time.Hour
		message := &messaging.Message{
			Android: &messaging.AndroidConfig{
				TTL:      &oneHour,
				Priority: "normal",
				Notification: &messaging.AndroidNotification{
					Title: "$GOOG up 1.43% on the day",
					Body:  "$GOOG gained 11.80 points to close at 835.67, up 1.43% on the day.",
					Icon:  "stock_ticker_update",
					Color: "#f45342",
				},
			},
			Token: v,
		}

		br, err := client.Send(context.Background(), message)
		if err != nil {
			log.Fatalln(err)
			return err
		}

		fmt.Printf("%d messages were sent successfully\n", br)
	}

	return nil
}
