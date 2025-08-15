#! /usr/bin/env bash

# Retrieve information about repository for creating discussion
RETRIEVE_INFO='
query ($owner: String!, $name: String!) {
	repository(owner: $owner, name: $name) {
		id
		discussionCategories(first: 10) {
			nodes {
				id
				name
			}
		}
	}
}'

RETRIEVE_INFO_DATA=$(gh api graphql -f query="$RETRIEVE_INFO" -F owner="$1" -F name="$2" | jq -r '.data.repository | @base64')

__jq() {
	echo -n "$RETRIEVE_INFO_DATA" | base64 --decode | jq -r "${1}"
}

REPO_ID=$(__jq '.id')
CATEGORY_ID=$(__jq '.discussionCategories.nodes[0].id')


# Create discussion
echo "Creating discussion using repository ID: " "$REPO_ID"
echo "Creating discussion using category ID: " "$CATEGORY_ID"

CREATE_DISCUSSION='
mutation ($repositoryId: ID!, $categoryId: ID!, $title: String!, $body: String!) {
	createDiscussion(input:{
		repositoryId: $repositoryId,
		categoryId: $categoryId,
		title: $title,
		body: $body,
	}) {
		discussion {
			id
		}
	}
}'

DISCUSSION_ID=$(gh api graphql -f query="$CREATE_DISCUSSION" -F "repositoryId=$REPO_ID" -F "categoryId=$CATEGORY_ID" -F "title=Demonstration" -F "body=Just demonstrating how to create and delete comment" --jq ".data.createDiscussion.discussion.id")


# Create discussion comment
echo "Creating comment using discussion ID: " "$DISCUSSION_ID"

CREATE_COMMENT='
mutation ($discussionId: ID!, $body: String!) {
	addDiscussionComment(input:{
		discussionId: $discussionId,
		body: $body,
	}) {
		comment {
			id
		}
	}
}'

COMMENT_ID=$(gh api graphql -f query="$CREATE_COMMENT" -F "discussionId=$DISCUSSION_ID" -F "body=Just a comment" --jq ".data.addDiscussionComment.comment.id")


# View discussion and comment
VIEW_DISCUSSION='
query ($discussionId: ID!) {
	node(id: $discussionId) {
		... on Discussion {
			id
			title
			body
			comments(first:10) {
				totalCount
				nodes {
					id
					body
					author {
						login
					}
				}
			}
		}
	}
}'

gh api graphql -f query="$VIEW_DISCUSSION" -F "discussionId=$DISCUSSION_ID"


# Delete discussion comment
echo "Deleting comment using comment ID: " "$COMMENT_ID"

DELETE_COMMENT='
mutation ($commentId: ID!) {
	deleteDiscussionComment(input: {
		id: $commentId,
	}) {
		comment {
			id
			body
			author {
				login
			}
		}
	}
}'

gh api graphql -f query="$DELETE_COMMENT" -F "commentId=$COMMENT_ID"
