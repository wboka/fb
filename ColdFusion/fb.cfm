<cfcomponent>
	<cfset this.PAGE_ACCESS_TOKEN = "" />
	<cfset this.VERIFY_TOKEN = "" />

	<cffunction name="webhook" access="remote" returntype="any">
		<cfargument name="body" required="true" />

		<cfif lCase(arguments.body.object) eq "page">
			<cfloop collection="#arguments.body.entry#" item="e">
				<cfset webhookEvent = e.messenging[1] />
				<cfset senderID = webhookEvent.sender.id />

				<cfif structKeyExists(webhookEvent, "message")>
					<cfset handleMessage(senderID, webhookEvent.message) />
				<cfelseif structKeyExists(webhookEvent, "postback")>>
					<cfset handlePostback(senderID, webhookEvent.postback) />
				</cfif>
			</cfloop>

			<cfreturn "EVENT_RECEIVED" />
		<cfelse>
			<cfreturn 404 />
		</cfif>
	</cffunction>

	<cffunction name="verify" access="remote" returntype="any">
		<cfargument name="hub" required="true" />

		<!--- Parse arguments from the webhook verification request --->
		<cfset mode = arguments['hub.mode'] />
		<cfset token = arguments['hub.verify_token'] />
		<cfset challenge = arguments['hub.challenge'] />

		<!--- Check if a token and mode were sent --->
		<cfif mode AND token>
			<!--- Check the mode and token sent are correct --->
			<cfif lCase(mode) eq "subscribe" AND token eq this.VERIFY_TOKEN>
				<!--- Respond with 200 OK and challenge token from the request --->
				<cfreturn challenge />
			<cfelse>
				<!--- Responds with '403 Forbidden' if verify tokens do not match --->
				<cfreturn 403 />
			</cfif>
		</cfif>
	</cffunction>

	<!--- Handles messages events --->
	<cffunction name="handleMessage" access="private" returntype="any">
		<cfargument name="senderPSID" required="true" />
		<cfargument name="receivedMessage" required="true" />

		<cfset response = "" />

		<!--- Checks if the message contains text --->
		<cfif structKeyExists(arguments.receivedMessage, "text")>
			<!--- Creates the payload for a basic text message, which will be added to the body of our request to the Send API --->
			<cfset response = {
				"text": "You sent the message: " & arguments.receivedMessage.text & ". Now send me an attachment!"
			} />
		<cfelseif structKeyExists(arguments.receivedMessage, "attachments")>
			<!--- Gets the URL of the message attachment --->
			<cfset attachmentURL = arguments.receivedMessage.attachments[1].payload.url />

			<cfset response = {
				"attachment": {
					"type": "template",
					"payload": {
						"template_type": "generic",
						"elements": [{
							"title": "Is this the right picture?",
							"subtitle": "Tap a button to answer.",
							"image_url": attachment_url,
							"buttons": [
								{
									"type": "postback",
									"title": "Yes!",
									"payload": "yes",
								},
								{
									"type": "postback",
									"title": "No!",
									"payload": "no",
								}
							],
						}]
					}
				}
			} />
		</cfif>

		<!--- Sends the response message --->
		<cfset callSendAPI(arguments.senderPSID, response) />

		<cfreturn true />
	</cffunction>

	<!--- Handles messaging_postbacks events --->
	<cffunction name="handlePostback" access="private" returntype="any">
		<cfargument name="senderPSID" required="true" />
		<cfargument name="receivedPostback" required="true" />

		<cfset response = "" />

		<!--- Get the payload for the postback --->
		<cfset payload = arguments.receivedPostback.payload />

		<!--- Set the response based on the postback payload --->
		<cfif payload eq "yes">
			<cfset response = { "text": "Thanks!" } />
		<cfelseif payload eq "no">
			<cfset response = { "text": "Oops, try sending another image." } />
		<cfelseif payload eq "lets_go">
			<cfset response = { "text": "View the menu, send me text, or send me a picture."} />
		</cfif>

		<!--- Send the message to acknowledge the postback --->
		<cfset callSendAPI(senderPSID, response) />
	</cffunction>

	<!--- Sends response messages via the Send API --->
	<cffunction name="callSendAPI" access="private" returntype="any">
		<cfargument name="senderPSID" required="true" />
		<cfargument name="response" required="true" />

		<!--- Construct the message body --->
		<cfset message = {
			"recipient": {
				"id": arguments.senderPSID
			},
			"message": arguments.response
		} />

		<!--- Send the HTTP request to the Messenger Platform --->
		<!--- request({
			"uri": "https://graph.facebook.com/v2.6/me/messages",
			"qs": { "access_token": PAGE_ACCESS_TOKEN },
			"method": "POST",
			"json": message
		}, (err, res, body) => {
			if (!err) {
				console.log('message sent!')
			} else {
				console.error("Unable to send message:" + err);
			}
		}); --->
	</cffunction>
</cfcomponent>
