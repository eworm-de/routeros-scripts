#!/bin/sh

sed \
	-e "/^:global CommitId/c :global CommitId \"${COMMITID:-unknown}\";" \
	-e "/^:global CommitInfo/c :global CommitInfo \"${COMMITINFO:-unknown}\";" \
	< "${1}"
