/// Entidad de dominio: una palabra del usuario reinterpretada como otra del
/// diccionario de señas, por ejemplo "padre" → "papa".
///
/// La produce la corrección semántica del backend (modelo de ML). Se muestra
/// al usuario para ser transparentes: sabe que su palabra fue interpretada,
/// no ignorada ni malentendida.
class SignInterpretation {
  final String original;
  final String interpreted;

  const SignInterpretation({
    required this.original,
    required this.interpreted,
  });
}
