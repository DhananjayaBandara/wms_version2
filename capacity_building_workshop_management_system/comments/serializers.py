from rest_framework import serializers
from .models import AdminComment
from workshops.models import Session

class AdminCommentSerializer(serializers.ModelSerializer):
    session = serializers.PrimaryKeyRelatedField(
        queryset=Session.objects.all(),
        required=True
    )
    comment = serializers.CharField(max_length=1000)
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)

    class Meta:
        model = AdminComment
        fields = ['id', 'session', 'comment', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']
    
    def validate(self, data):
        session = data.get('session')
        if not session:
            raise serializers.ValidationError("Session is required.")
        return data
    
    def create(self, validated_data):
        return AdminComment.objects.create(**validated_data)
    
    def update(self, instance, validated_data):
        instance.session = validated_data.get('session', instance.session)
        instance.comment = validated_data.get('comment', instance.comment)
        instance.save()
        return instance