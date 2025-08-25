from rest_framework import serializers
from user_types.models import ParticipantType
from user_types.serializers import ParticipantTypeSerializer
from users.models import Participant
import re

def validate_email_format(email):
    if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
        raise serializers.ValidationError("Invalid email format.")
    return email

def validate_contact_number(number):
    if not re.match(r"^\d{10}$", number):
        raise serializers.ValidationError("Contact number must be exactly 10 digits.")
    return number

def validate_nic(nic):
    if not (re.match(r"^\d{9}[vV]$", nic) or re.match(r"^\d{12}$", nic)):
        raise serializers.ValidationError("NIC must be 9 digits followed by 'V' or 12 digits.")
    return nic


class ParticipantSerializer(serializers.ModelSerializer):
    participant_type_id = serializers.PrimaryKeyRelatedField(
        queryset=ParticipantType.objects.all(),
        source='participant_type',
        write_only=True
    )
    participant_type = ParticipantTypeSerializer(read_only=True)

    class Meta:
        model = Participant
        fields = [
            'id', 'name', 'email', 'contact_number', 'nic',
            'district', 'gender', 'participant_type', 'participant_type_id', 'properties'
        ]

    def validate_email(self, value):
        return validate_email_format(value)

    def validate_contact_number(self, value):
        return validate_contact_number(value)

    def validate_nic(self, value):
        return validate_nic(value)

    def validate(self, data):
        participant_type = data.get('participant_type')
        submitted_properties = data.get('properties', {})
        required_fields = participant_type.properties
        missing_fields = [f for f in required_fields if f not in submitted_properties]

        if missing_fields:
            raise serializers.ValidationError({
                "properties": f"Missing required fields for {participant_type.name}: {', '.join(missing_fields)}"
            })

        return data