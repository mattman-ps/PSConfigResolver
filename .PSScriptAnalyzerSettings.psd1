@{
    # Use Recommended rules as base with some customizations
    Rules = @{
        # PSAvoidDefaultValueSwitchParameter - Exclude $false defaults
        PSAvoidDefaultValueSwitchParameter = @{
            Exclude = @()
        }

        # PSAvoidGlobalAlias - Warn about global alias usage
        PSAvoidGlobalAlias = @{
            Exclude = @()
        }

        # PSAvoidGlobalFunction - Warn about global function definitions
        PSAvoidGlobalFunction = @{
            Exclude = @()
        }

        # PSAvoidGlobalVariable - Warn about global variable usage
        PSAvoidGlobalVariable = @{
            Exclude = @()
        }

        # PSAvoidLongLines - Warn about lines exceeding 120 characters
        PSAvoidLongLines = @{
            Line = 120
            Exclude = @()
        }

        # PSAvoidShouldContinueWithoutForce - Warn about missing Force parameter confirmation
        PSAvoidShouldContinueWithoutForce = @{
            Exclude = @()
        }

        # PSAvoidUsingCmdletAliases - Use full cmdlet names instead of aliases
        PSAvoidUsingCmdletAliases = @{
            Exclude = @()
        }

        # PSAvoidUsingComputedProperties - Warn about computed properties
        PSAvoidUsingComputedProperties = @{
            Exclude = @()
        }

        # PSAvoidUsingConvertToSecureStringWithPlainText - Warn about ConvertTo-SecureString with plaintext
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Exclude = @()
        }

        # PSAvoidUsingDoubleQuotedStrings - Use single quotes when possible
        PSAvoidUsingDoubleQuotedStrings = @{
            Exclude = @()
        }

        # PSAvoidUsingEmptyCatchBlock - Warn about empty catch blocks
        PSAvoidUsingEmptyCatchBlock = @{
            Exclude = @()
        }

        # PSAvoidUsingInvokeExpression - Avoid using Invoke-Expression
        PSAvoidUsingInvokeExpression = @{
            Exclude = @()
        }

        # PSAvoidUsingPlainTextForPassword - Warn about plaintext passwords
        PSAvoidUsingPlainTextForPassword = @{
            Exclude = @()
        }

        # PSAvoidUsingPositionalParameters - Recommend named parameters
        PSAvoidUsingPositionalParameters = @{
            Exclude = @()
        }

        # PSAvoidUsingUsernameAndPasswordParams - Warn about separate username/password parameters
        PSAvoidUsingUsernameAndPasswordParams = @{
            Exclude = @()
        }

        # PSAvoidUsingWildcardCharactersInName - Warn about wildcards in function/variable names
        PSAvoidUsingWildcardCharactersInName = @{
            Exclude = @()
        }

        # PSMissingModuleManifestField - Check for missing manifest fields
        PSMissingModuleManifestField = @{
            Exclude = @()
        }

        # PSPlaceCloseBrace - Enforce consistent brace placement
        PSPlaceCloseBrace = @{
            Enable = $true
            IgnoreOneLineBlock = $true
        }

        # PSPlaceOpenBrace - Enforce consistent brace placement
        PSPlaceOpenBrace = @{
            Enable = $true
            IgnoreOneLineBlock = $true
        }

        # PSPossibleIncorrectComparisonWithNull - Warn about null comparisons
        PSPossibleIncorrectComparisonWithNull = @{
            Exclude = @()
        }

        # PSPossibleIncorrectUsageOfRedirectionOperator - Warn about redirection operator misuse
        PSPossibleIncorrectUsageOfRedirectionOperator = @{
            Exclude = @()
        }

        # PSProvideCommentHelp - Recommend comment-based help
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            BlockComment = $true
        }

        # PSReviewUnusedParameter - Warn about unused parameters
        PSReviewUnusedParameter = @{
            Exclude = @()
        }

        # PSShouldProcess - Check ShouldProcess implementation
        PSShouldProcess = @{
            Exclude = @()
        }

        # PSUseApprovedVerbs - Use approved PowerShell verbs
        PSUseApprovedVerbs = @{
            Exclude = @()
        }

        # PSUseBOMForUnicodeEncodedFile - Use BOM for Unicode files
        PSUseBOMForUnicodeEncodedFile = @{
            Exclude = @()
        }

        # PSUseCmdletCorrectly - Correct usage of cmdlets
        PSUseCmdletCorrectly = @{
            Exclude = @()
        }

        # PSUseConsistentIndentation - Use consistent indentation (4 spaces)
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            IndentationSize = 4
        }

        # PSUseConsistentWhitespace - Use consistent whitespace
        PSUseConsistentWhitespace = @{
            Enable = $true
        }

        # PSUseDeclaredVarsMoreThanAssignments - Warn about declared but unused variables
        PSUseDeclaredVarsMoreThanAssignments = @{
            Exclude = @()
        }

        # PSUseFunctionAliasAttributes - Use Alias attribute for aliases
        PSUseFunctionAliasAttributes = @{
            Exclude = @()
        }

        # PSUseIntegratedSecurityForSQLConnection - Warn about SQL connection security
        PSUseIntegratedSecurityForSQLConnection = @{
            Exclude = @()
        }

        # PSUseLiteralInitializerForHashtable - Use splatting for hashtables
        PSUseLiteralInitializerForHashtable = @{
            Exclude = @()
        }

        # PSUsePSCredentialType - Use PSCredential for credentials
        PSUsePSCredentialType = @{
            Exclude = @()
        }

        # PSUseSingularNouns - Use singular nouns for function names
        PSUseSingularNouns = @{
            Exclude = @()
        }

        # PSUseOutputTypeCorrectly - Correct OutputType declaration
        PSUseOutputTypeCorrectly = @{
            Exclude = @()
        }

        # PSUseProcessBlockForPipelineCommand - Use Process block for pipeline-capable commands
        PSUseProcessBlockForPipelineCommand = @{
            Exclude = @()
        }

        # PSUseToExportFieldsInManifest - Use proper export fields in manifest
        PSUseToExportFieldsInManifest = @{
            Exclude = @()
        }

        # PSUseUsingVariableForFilteringHashtables - Use $_ filtering
        PSUseUsingVariableForFilteringHashtables = @{
            Exclude = @()
        }
    }

    # Exclude test files and dist folder from analysis
    ExcludeRules = @(
        'PSAvoidUsingDoubleQuotedStrings'  # Allow double quotes in test output
    )

    # Include rules
    IncludeRules = @(
        'PSAlignAssignmentStatement'
        'PSAvoidAssignmentToAutomaticVariable'
        'PSAvoidDefaultValueSwitchParameter'
        'PSAvoidGlobalAlias'
        'PSAvoidGlobalVariable'
        'PSAvoidLongLines'
        'PSAvoidSemicolonsAsLineTerminators'
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingConvertToSecureStringWithPlainText'
        'PSAvoidUsingEmptyCatchBlock'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingPlainTextForPassword'
        'PSAvoidUsingPositionalParameters'
        'PSAvoidUsingWriteHost'
        'PSMissingModuleManifestField'
        'PSPlaceCloseBrace'
        'PSPlaceOpenBrace'
        'PSProvideCommentHelp'
        'PSReviewUnusedParameter'
        'PSShouldProcess'
        'PSUseApprovedVerbs'
        'PSUseBOMForUnicodeEncodedFile'
        'PSUseCmdletCorrectly'
        'PSUseConsistentIndentation'
        'PSUseConsistentWhitespace'
        'PSUseLiteralInitializerForHashtable'
        'PSUseOutputTypeCorrectly'
    )
}
