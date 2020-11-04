// SPDX-FileCopyrightText: 2020 Carson Black <uhhadd@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Window 2.10
import QtQuick.Layouts 1.10
import org.kde.kirigami 2.13 as Kirigami
import QtQuick.Controls 2.10 as QQC2
import com.github.HarmonyDevelopment.Staccato 1.0

Kirigami.PageRoute {
	name: "messages"
	cache: true

	Kirigami.ScrollablePage {
		id: messagesRoute
		Kirigami.Theme.colorSet: Kirigami.Theme.View
		property var model: Kirigami.PageRouter.data

		footer: QQC2.ToolBar {
			position: QQC2.ToolBar.Footer

			ColumnLayout {
				anchors {
					left: parent.left
					right: parent.right
				}
				QQC2.Control {
					id: replyingBar
					visible: replyingToID !== ""
					property string replyingToID: ""
					property string replyingToAuthor: ""
					property string replyingToContent: ""

					padding: Kirigami.Units.gridUnit
					contentItem: RowLayout {
						Kirigami.Icon {
							source: "dialog-messages"
						}
						ColumnLayout {
							Kirigami.Heading {
								level: 3
								text: replyingBar.replyingToAuthor
								textFormat: TextEdit.MarkdownText
							}
							QQC2.Label {
								text: replyingBar.replyingToContent
								textFormat: TextEdit.MarkdownText

								Layout.fillWidth: true
							}
							Layout.fillWidth: true
						}
						QQC2.ToolButton {
							flat: true
							icon.name: "dialog-close"
							onClicked: replyingBar.replyingToID = ""
						}
					}

					Layout.fillWidth: true
				}
				RowLayout {
					QQC2.TextField {
						id: messageField
						placeholderText: "Write a message..."

						Layout.fillWidth: true

						function send() {
							Kirigami.PageRouter.data.sendMessage(text, replyingBar.replyingToID)
							text = ""
							replyingBar.replyingToID = ""
						}

						Keys.onEscapePressed: replyingBar.replyingToID = ""

						onAccepted: send()
					}
					QQC2.Button {
						text: "Send"
						onClicked: messageField.send()
					}
				}
			}
		}

		ListView {
			id: messagesView
			model: Kirigami.PageRouter.data
			verticalLayoutDirection: ListView.BottomToTop
			bottomMargin: 0
			topMargin: 0
			leftMargin: Kirigami.Units.gridUnit
			rightMargin: Kirigami.Units.gridUnit
			spacing: Kirigami.Units.gridUnit

			section {
				criteria: ViewSection.FullString
				property: "authorIDAndAvatar"
				delegate: Item {
					required property var section

					Kirigami.Avatar {
						name: parent.section.split("\t")[2]
						source: parent.section.split("\t")[1]

						width: Kirigami.Units.gridUnit * 2
						height: Kirigami.Units.gridUnit * 2

						anchors {
							bottom: parent.top
						}
					}

					width: 0
					height: 0
				}
			}

			delegate: QQC2.Control {
				padding: 0
				topPadding: 0
				leftPadding: 0
				rightPadding: 0
				bottomPadding: 0

				background: MouseArea {
					acceptedButtons: Qt.RightButton
					onClicked: {
						if ((messagesRoute.model.userID() == authorID || messagesRoute.model.isOwner()) && mouse.button === Qt.RightButton)
							messageMenu.popup()
					}

					QQC2.Menu {
						id: messageMenu

						QQC2.MenuItem {
							text: "Edit"
							visible: messagesRoute.model.userID() == authorID
							onTriggered: {
								messageBlock.edit = true
							}
						}
						QQC2.MenuItem {
							text: "Delete"
							visible: messagesRoute.model.userID() == authorID || messagesRoute.model.isOwner()
							onTriggered: {
								messagesRoute.model.deleteMessage(messageID)
							}
						}
						QQC2.MenuItem {
							text: "Reply"
							onTriggered: {
								replyingBar.replyingToID = messageID
								replyingBar.replyingToAuthor = authorName
								replyingBar.replyingToContent = content
							}
						}
					}
				}

				contentItem: ColumnLayout {
					id: messageDelegate
					property string modelMessageID: messageID

					QQC2.Control {
						id: messageBlock
						property bool edit: false
						visible: content != ""

						padding: Kirigami.Units.largeSpacing * 2

						Layout.minimumWidth: Kirigami.Units.gridUnit * 3
						Layout.maximumWidth: (applicationWindow().wideScreen ? Math.max(messagesView.width / 3, Kirigami.Units.gridUnit * 15) : (messagesView.width * 0.9)) - Layout.leftMargin
						Layout.leftMargin: Kirigami.Units.gridUnit * 2 + Kirigami.Units.largeSpacing
						Kirigami.Theme.colorSet: Kirigami.Theme.Window

						implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
						implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)

						background: Rectangle {
							radius: 4
							color: Kirigami.Theme.backgroundColor
						}
						contentItem: ColumnLayout {
							QQC2.Label {
								visible: shouldShowAuthorInfo
								text: authorName

								font.pixelSize: Kirigami.Units.gridUnit * (4/5)
								font.pointSize: -1
								wrapMode: Text.Wrap

								Layout.alignment: Qt.AlignTop
							}
							QQC2.Control {
								visible: replyToID !== undefined
								padding: 0

								background: Item {
									Rectangle {
										anchors {
											left: parent.left
											top: parent.top
											bottom: parent.bottom
										}
										width: 2
										color: Kirigami.Theme.highlightColor
									}
								}
								contentItem: ColumnLayout {
									property var peeked: replyToID !== undefined ? messagesView.model.peekMessage(replyToID) || {} : {}
									spacing: 1
									QQC2.Label {
										text: parent.peeked["authorName"] || ""
										elide: Text.ElideRight
										color: Kirigami.Theme.highlightColor
										textFormat: TextEdit.MarkdownText

										Layout.fillWidth: true
									}
									QQC2.Label {
										text: parent.peeked["content"] || ""
										elide: Text.ElideRight
										textFormat: TextEdit.MarkdownText

										Layout.fillWidth: true
									}
								}

								Layout.fillWidth: true
								Layout.maximumWidth: messageBlock.Layout.maximumWidth * 0.9
							}
							GridLayout {
								QQC2.Label {
									visible: !messageBlock.edit
									text: content
									textFormat: TextEdit.MarkdownText

									font.pixelSize: Kirigami.Units.gridUnit * (3/4)
									font.pointSize: -1
									wrapMode: Text.Wrap

									Layout.alignment: Qt.AlignBottom
									Layout.maximumWidth: messageBlock.Layout.maximumWidth * 0.9
								}
								QQC2.TextField {
									visible: messageBlock.edit
									text: content

									Keys.onEscapePressed: messageBlock.edit = false

									onAccepted: {
										messageBlock.edit = false
										messagesRoute.model.editMessage(messageID, text)
									}

									Layout.alignment: Qt.AlignBottom
								}
								Item { Layout.fillWidth: true }
								QQC2.Label {
									text: `${("0"+date.getHours()).slice(-2)}:${("0"+date.getMinutes()).slice(-2)}`
									opacity: 0.5

									font.pixelSize: Kirigami.Units.gridUnit * (1/2)
									font.pointSize: -1
									Layout.alignment: Qt.AlignBottom | Qt.AlignRight
								}
							}
						}
					}
					Repeater {
						model: actions
						delegate: MessageAction {
							messageID: messageDelegate.modelMessageID
							Layout.leftMargin: Kirigami.Units.gridUnit * 2 + Kirigami.Units.largeSpacing
						}
					}
					Repeater {
						model: embeds
						delegate: Embed {
							Layout.leftMargin: Kirigami.Units.gridUnit * 2 + Kirigami.Units.largeSpacing
						}
					}
				}
			}

			add: Transition {
				NumberAnimation {
					duration: Kirigami.Units.shortDuration
					properties: "y"
					easing.type: Easing.InOutCubic
				}
			}
			displaced: Transition {
				NumberAnimation {
					duration: Kirigami.Units.shortDuration
					properties: "y"
					easing.type: Easing.InOutCubic
				}
			}
		}
	}
}
