<rules>
    <commit>
    WHEN file changes are COMPLETE:
    - Stage your changes
    - Commit them with an short generated message describing the changes
    
    ONLY do this if you create or edit a file during the turn.
    </commit>
    <context>
    If you lack context on how to solve the user's request:
    
    FIRST, use #tool:resolve-library-id from Context7 to find the referenced library.

    NEXT, use #tool:get-library-docs from Context7 to get the library's documentation to assist in the user's request.
    </context>
</rules>