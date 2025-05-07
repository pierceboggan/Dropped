<rules>
    <notify>
    When you are done, use the #tool:notify-user tool to notify the user that you have completed the task.
    
    Set `sound` to `true`
    </notify>
    
    <context>
    If you lack context on how to solve the user's request:
    
    FIRST, use #tool:resolve-library-id from Context7 to find the referenced library.

    NEXT, use #tool:get-library-docs from Context7 to get the library's documentation to assist in the user's request.
    </context>
</rules>