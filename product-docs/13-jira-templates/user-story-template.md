# Jira User Story Template

## User Story Overview

**Story Title**: [Insert a clear, concise story title that describes the functionality - Example: "User can reset password via email"]

**User Story Statement**: 
```
As a [type of user/persona]
I want [some goal/functionality] 
So that [benefit/value/reason]
```

**Example**:
```
As a registered user
I want to reset my password using my email address
So that I can regain access to my account when I forget my password
```

## User Story Fields Configuration

### Required Fields

**Issue Type**: Story

**Project**: [Insert project key - Example: PROJ]

**Summary**: [Same as Story Title above - keep consistent]

**Description**:
```
## User Story
[Repeat the user story statement from above]

## Background
[Provide context about why this story is needed - Example: "Users frequently forget their passwords and currently have no self-service way to reset them, resulting in increased support tickets and user frustration"]

## User Value
[Explain the value this provides to the user - Example: "Enables users to independently resolve password issues without waiting for support, improving user experience and reducing friction in account access"]

## Business Value
[Describe the business benefit - Example: "Reduces password-related support tickets by an estimated 60%, freeing up support team for more complex issues and improving customer satisfaction scores"]

## Assumptions
[List any assumptions being made - Example:
- Users have access to the email address associated with their account
- Email delivery is reliable and timely
- Users understand basic email functionality]

## Dependencies
[Identify dependencies on other work or external factors - Example:
- Email service integration must be completed first
- Password policy rules must be defined
- Security review required for password reset flow]

## Notes
[Any additional context, research findings, or implementation notes - Example: "User research shows 45% of support tickets are password-related. Benchmark analysis shows industry standard is 24-hour reset link expiration"]
```

**Reporter**: [Insert reporter name - typically Product Owner or Business Analyst]

**Assignee**: [Insert assignee name - typically assigned during sprint planning]

**Priority**: [Select appropriate priority level]
- Highest (Critical user need, blocking)
- High (Important user functionality)
- Medium (Standard user improvement)
- Low (Nice to have enhancement)

**Labels**: [Add relevant labels for categorization]
- story-[domain] (Example: story-authentication)
- feature-[feature-name] (Example: feature-account-management)
- user-[persona] (Example: user-customer)
- [technical labels if applicable]

### Story-Specific Fields

**Story Points**: [Estimate using your team's pointing scale - Example: "5"]
- 1: Very simple, minimal work
- 2: Simple, straightforward implementation
- 3: Moderate complexity, some dependencies
- 5: Complex, multiple components or integrations
- 8: Very complex, significant effort required
- 13: Very large, consider breaking down further

**Epic Link**: [Link to parent epic - Example: PROJ-123]

**Parent**: [Link to parent feature if applicable - Example: PROJ-456]

**Component/s**: [Select relevant components]
- Frontend
- Backend
- API
- Database
- [Other specific components]

**Affects Version/s**: [Version where issue was identified, if applicable]

**Fix Version/s**: [Target version for delivery - Example: "2025.3.0"]

**Sprint**: [Sprint assignment - typically set during sprint planning]

### Additional Context Fields

**User Persona**: [Specific user type this story addresses]
- Primary User: [Main user persona - Example: "End Customer"]
- Secondary Users: [Other affected users - Example: "Customer Support Agent"]

**Story Category**: [Type of user story]
- New Feature
- Enhancement
- Bug Fix
- Technical Debt
- Research/Spike

**Technical Complexity**: [Development complexity assessment]
- Simple (Straightforward UI/logic changes)
- Medium (Multiple components, some business logic)
- Complex (Integration work, complex business rules)
- Very Complex (Architectural changes, multiple systems)

## Acceptance Criteria

### Detailed Acceptance Criteria

**Given-When-Then Format** (Recommended):

**Scenario 1: [Scenario name]**
```
Given [initial context/precondition]
When [action taken by user]
Then [expected result/outcome]
```

**Example**:
```
Scenario 1: Valid Password Reset Request
Given I am on the login page and have forgotten my password
When I click "Forgot Password" and enter my valid email address
Then I should receive a password reset email within 5 minutes
```

**Scenario 2: [Second scenario name]**
```
Given [initial context/precondition]
When [action taken by user]
Then [expected result/outcome]
And [additional expected result if applicable]
```

**Scenario 3: [Additional scenarios as needed]**

### Functional Acceptance Criteria

**Primary Flow**:
- [ ] [Criterion 1 - Example: User can access password reset from login page]
- [ ] [Criterion 2 - Example: Valid email addresses receive reset emails]
- [ ] [Criterion 3 - Example: Reset links expire after 24 hours]
- [ ] [Criterion 4 - Example: Password reset form validates new password requirements]
- [ ] [Criterion 5 - Example: User is logged in automatically after successful reset]

**Error Handling**:
- [ ] [Error Criterion 1 - Example: Invalid email addresses show appropriate error message]
- [ ] [Error Criterion 2 - Example: Expired reset links show clear error and option to request new link]
- [ ] [Error Criterion 3 - Example: Weak passwords are rejected with helpful feedback]

**Edge Cases**:
- [ ] [Edge Case 1 - Example: Multiple reset requests within short timeframe are handled gracefully]
- [ ] [Edge Case 2 - Example: Reset attempt for non-existent account doesn't reveal account status]

### Non-Functional Acceptance Criteria

**Performance**:
- [ ] Password reset email sent within 5 minutes
- [ ] Reset page loads in under 3 seconds
- [ ] Password update process completes in under 2 seconds

**Security**:
- [ ] Reset tokens are cryptographically secure
- [ ] Reset links are single-use only
- [ ] Password requirements are enforced
- [ ] Previous password cannot be reused immediately

**Usability**:
- [ ] Form validation provides clear, helpful error messages
- [ ] Process works on mobile and desktop browsers
- [ ] Accessible to users with disabilities (WCAG 2.1 AA)
- [ ] Text is clear and instructional

### Technical Acceptance Criteria

**Frontend**:
- [ ] Responsive design works on mobile and desktop
- [ ] Form validation works both client-side and server-side
- [ ] Loading states are shown during processing
- [ ] Success/error messages are clearly displayed

**Backend**:
- [ ] API endpoints handle all specified scenarios
- [ ] Database updates are atomic and reliable
- [ ] Email service integration is robust with retry logic
- [ ] Audit logging captures all password reset attempts

**Integration**:
- [ ] Email templates render correctly across major email clients
- [ ] Integration with user authentication system
- [ ] Proper error handling for email service failures

## Definition of Ready

**Story is ready for development when**:
- [ ] User story is clearly written and understood
- [ ] Acceptance criteria are specific and testable
- [ ] Dependencies are identified and resolved
- [ ] Design mockups are available (if UI changes required)
- [ ] Technical approach is understood by development team
- [ ] Story is appropriately sized (8 points or less)
- [ ] Priority and value are clear to Product Owner

## Definition of Done

**Story is complete when**:
- [ ] All acceptance criteria are met and tested
- [ ] Code is developed and peer reviewed
- [ ] Unit tests written and passing (minimum 80% coverage)
- [ ] Integration tests implemented and passing
- [ ] User acceptance testing completed by Product Owner
- [ ] Code deployed to staging environment
- [ ] Documentation updated (if applicable)
- [ ] No critical or high-priority bugs remain

## Testing Strategy

### Test Scenarios

**Happy Path Testing**:
1. [Test 1] - [Expected result]
2. [Test 2] - [Expected result]
3. [Test 3] - [Expected result]

**Error Path Testing**:
1. [Error Test 1] - [Expected error handling]
2. [Error Test 2] - [Expected error handling]
3. [Error Test 3] - [Expected error handling]

**Edge Case Testing**:
1. [Edge Case 1] - [Expected behavior]
2. [Edge Case 2] - [Expected behavior]

### Test Data Requirements

**Valid Test Data**:
- [Describe valid test data needed - Example: "Active user accounts with verified email addresses"]

**Invalid Test Data**:
- [Describe invalid test data needed - Example: "Inactive accounts, invalid email formats, expired tokens"]

**Edge Case Data**:
- [Describe edge case data - Example: "Accounts with pending email changes, recently deleted accounts"]

## Implementation Notes

### Technical Considerations

**Frontend Implementation**:
- [Framework/technology requirements]
- [Specific UI component needs]
- [Client-side validation requirements]
- [Responsive design considerations]

**Backend Implementation**:
- [API endpoint specifications]
- [Database schema changes]
- [Business logic requirements]
- [Security implementation details]

**Integration Requirements**:
- [External service integrations]
- [Internal system dependencies]
- [Configuration requirements]

### Design Requirements

**UI/UX Needs**:
- [ ] Wireframes/mockups provided
- [ ] Design system components identified
- [ ] Accessibility requirements defined
- [ ] Error state designs available

**Content Requirements**:
- [ ] Error messages written and approved
- [ ] Email templates created and tested
- [ ] Help text and instructions defined
- [ ] Success messages defined

---

## Template Usage Instructions

### Before Creating the Story
1. **User Research**: Ensure user need is validated through research or feedback
2. **Epic/Feature Alignment**: Confirm story supports parent epic and feature goals
3. **Sizing Assessment**: Verify story can be completed within one sprint
4. **Dependency Check**: Identify and resolve blocking dependencies

### During Story Creation
1. **Clear User Voice**: Write from perspective of actual user persona
2. **Specific Acceptance Criteria**: Make criteria testable and unambiguous
3. **Value Focus**: Clearly articulate user and business value
4. **Size Appropriately**: Break down large stories into smaller ones

### After Story Creation
1. **Team Review**: Present story to development team for questions/clarification
2. **Design Coordination**: Initiate design work if UI changes are needed
3. **Technical Planning**: Allow team to plan technical approach
4. **Sprint Inclusion**: Include in appropriate sprint based on priority

### Story Management During Development
- Update status regularly as work progresses
- Clarify acceptance criteria if questions arise
- Communicate scope changes immediately to stakeholders
- Conduct acceptance testing promptly when development is complete

---

**Template Version**: 1.0
**Last Updated**: 2025-07-05
**Template Owner**: [Insert Product Management Team]
**Next Review**: [Insert review date 90 days from creation]