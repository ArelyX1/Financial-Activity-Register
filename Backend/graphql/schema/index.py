import strawberry
from strawberry.schema.config import StrawberryConfig
from account_provider.adapters.driving.graphql.account_provider_resolver import Query as AccountProviderQuery, Mutation as AccountProviderMutation
from auth.adapters.driving.graphql.auth_resolver import Query as AuthQuery, Mutation as AuthMutation
from boundaries.adapters.driving.graphql.boundarie_resolver import Query as BoundarieQuery
from identification_type.adapters.driving.graphql.identification_type_resolver import Query as IdentificationTypeQuery, Mutation as IdentificationTypeMutation
from person.adapters.driving.graphql.person_resolver import Query as PersonQuery, Mutation as PersonMutation, PersonRolesQuery
from user_account.adapters.driving.graphql.user_account_resolver import Mutation as UserAccountMutation
from password_recovery.adapters.driving.graphql.password_recovery_resolver import Mutation as PasswordRecoveryMutation
from role.adapters.driving.graphql.role_resolver import Query as RoleQuery, Mutation as RoleMutation

# APIs desactivadas temporalmente (no expuestas en GraphQL, no eliminadas):
# from questionnaire.adapters.driving.graphql.questionnaire_resolver import Query as QuestionnaireQuery, Mutation as QuestionnaireMutation
# from dashboard.adapters.driving.graphql.dashboard_resolver import Query as DashboardQuery
# from person.adapters.driving.graphql.person_resolver import Query as PersonQuery
# from user_account.adapters.driving.graphql.user_account_resolver import Query as UserAccountQuery


@strawberry.type
class RootQuery(AccountProviderQuery, AuthQuery, BoundarieQuery, IdentificationTypeQuery, RoleQuery, PersonQuery, PersonRolesQuery):
    pass


@strawberry.type
class RootMutation(AccountProviderMutation, AuthMutation, IdentificationTypeMutation, PersonMutation, UserAccountMutation, PasswordRecoveryMutation, RoleMutation):
    pass


schema = strawberry.Schema(query=RootQuery, mutation=RootMutation, config=StrawberryConfig(auto_camel_case=False))
