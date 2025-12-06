enum UserType {
  user('USER', '유저'),
  admin('MANAGER', '관리자'),      // 서버: MANAGER = 관리자
  manager('STAFF', '담당자'),       // 서버: STAFF = 담당자
  headquarters('HEADQUARTERS', '본사');

  const UserType(this.code, this.displayName);

  final String code;
  final String displayName;

  static UserType fromCode(String code) {
    return UserType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => UserType.user,
    );
  }
}