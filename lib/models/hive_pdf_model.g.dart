// GENERATED CODE - DO NOT MODIFY BY HAND

/*
  Datei: hive_pdf_model.g.dart
  Zweck: Automatisch generierter TypeAdapter für PdfEintrag (Hive)
  Autor: Automatisch generiert durch `build_runner`
  Letzte Änderung: Wird bei jeder Code-Generierung überschrieben

  Hinweis:
  Diese Datei wird von `build_runner` automatisch erstellt.
  Änderungen in dieser Datei gehen beim nächsten Build verloren.

  Verwendet in:
  - Hive-Datenbank zum Lesen und Schreiben von PdfEintrag-Objekten
*/

part of 'hive_pdf_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfEintragAdapter extends TypeAdapter<PdfEintrag> {
  @override
  final int typeId = 0;

  @override
  PdfEintrag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfEintrag(
      id: fields[0] as String,
      titel: fields[1] as String,
      fach: fields[2] as String,
      klassenstufe: fields[3] as String,
      zyklus: fields[4] as String,
      stufe: fields[5] as String,
      uploader: fields[6] as String,
      text: fields[7] as String,
      timestamp: fields[8] as DateTime,
      pdfUrl: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PdfEintrag obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titel)
      ..writeByte(2)
      ..write(obj.fach)
      ..writeByte(3)
      ..write(obj.klassenstufe)
      ..writeByte(4)
      ..write(obj.zyklus)
      ..writeByte(5)
      ..write(obj.stufe)
      ..writeByte(6)
      ..write(obj.uploader)
      ..writeByte(7)
      ..write(obj.text)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.pdfUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfEintragAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
