enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,

  /// 서버에 닿지 못해 인증 상태를 확인하지 못한 상태.
  ///
  /// [unauthenticated] 와 구분해야 한다. 로그아웃된 것이 아니라 **아직 모르는 것**이며,
  /// 저장된 토큰은 그대로 남아 있다. 연결이 회복되면 재시도로 복구된다.
  networkUnavailable,

  error,
}